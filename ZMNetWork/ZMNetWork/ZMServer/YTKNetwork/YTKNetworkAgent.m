//
//  YTKNetworkAgent.m
//
//  Copyright (c) 2012-2014 YTKNetwork https://github.com/yuantiku
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "YTKNetworkAgent.h"
#import "YTKNetworkConfig.h"
#import "YTKNetworkPrivate.h"
#import "AFDownloadRequestOperation.h"

@implementation YTKNetworkAgent {
    AFHTTPRequestOperationManager *_manager;
    YTKNetworkConfig *_config;
    NSMutableDictionary *_requestsRecord;
}

+ (YTKNetworkAgent *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _config = [YTKNetworkConfig sharedInstance];
        _manager = [AFHTTPRequestOperationManager manager];
        _requestsRecord = [NSMutableDictionary dictionary];
        _manager.operationQueue.maxConcurrentOperationCount = 4;
    }
    return self;
}

- (NSString *)buildRequestUrl:(YTKBaseRequest *)request {
    NSString *detailUrl = [request requestUrl];
    if ([detailUrl hasPrefix:@"http"]) {
        return detailUrl;
    }
    // filter url
    NSArray *filters = [_config urlFilters];
    for (id<YTKUrlFilterProtocol> f in filters) {
        detailUrl = [f filterUrl:detailUrl withRequest:request];
    }

    NSString *baseUrl;
    if ([request useCDN]) {
        if ([request cdnUrl].length > 0) {
            baseUrl = [request cdnUrl];
        } else {
            baseUrl = [_config cdnUrl];
        }
    } else {
        if ([request baseUrl].length > 0) {
            baseUrl = [request baseUrl];
        } else {
            baseUrl = [_config baseUrl];
        }
    }
    return [NSString stringWithFormat:@"%@%@", baseUrl, detailUrl];
}

- (void)addRequest:(YTKBaseRequest *)request {
    YTKRequestMethod method = [request requestMethod];
    NSString *url = [self buildRequestUrl:request];
    id param = request.requestArgument;
    AFConstructingBlock constructingBlock = [request constructingBodyBlock];

    // 设置返回对象的格式，YTKRequestSerializerTypeHTTP代表返回二进制格式，YTKRequestSerializerTypeJSON代表返回一个json的根对象（NSDictionary或者NSArray）
    if (request.requestSerializerType == YTKRequestSerializerTypeHTTP) {
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == YTKRequestSerializerTypeJSON) {
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    _manager.requestSerializer.timeoutInterval = [request requestTimeoutInterval];

    // 如果请求需要授权证书，这里设置用户名和密码
    NSArray *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:(NSString *)authorizationHeaderFieldArray.firstObject
                                                                   password:(NSString *)authorizationHeaderFieldArray.lastObject];
    }
    
    // 设置其他HTTP header
    NSDictionary *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (id httpHeaderField in headerFieldValueDictionary.allKeys) {
            id value = headerFieldValueDictionary[httpHeaderField];
            if ([httpHeaderField isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
                [_manager.requestSerializer setValue:(NSString *)value forHTTPHeaderField:(NSString *)httpHeaderField];
            } else {
                YTKLog(@"Error, class of key/value in headerFieldValueDictionary should be NSString.");
            }
        }
    }

    // 如果创建了自定义的NSURLRequest对象，就使用自定的对象
    NSURLRequest *customUrlRequest= [request buildCustomUrlRequest];
    if (customUrlRequest) {
        // 创建 AFHTTPRequestOperation 对象
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:customUrlRequest];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
            // 处理结果
            [self handleRequestResult:op];
        } failure:^(AFHTTPRequestOperation *op, NSError *error) {
            [self handleRequestResult:op];
        }];
        request.requestOperation = operation;
        operation.responseSerializer = _manager.responseSerializer;
        // 添加到请求队列
        [_manager.operationQueue addOperation:operation];
    } else {
        // 没有自定义NSURLRequest，需要手动创建
        if (method == YTKRequestMethodGet) {
            // 如果需要断点续传下载文件
            if (request.resumableDownloadPath) {
                // 拼接参数到url
                NSString *filteredUrl = [YTKNetworkPrivate urlStringWithOriginUrlString:url appendParameters:param];

                NSURLRequest *requestUrl = [NSURLRequest requestWithURL:[NSURL URLWithString:filteredUrl]];
                AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:requestUrl targetPath:request.resumableDownloadPath shouldResume:YES];
                // 设置断点续传的进度回调block
                [operation setProgressiveDownloadProgressBlock:request.resumableDownloadProgressBlock];
                // 整个请求完成的回调block
                [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
                    [self handleRequestResult:op];
                } failure:^(AFHTTPRequestOperation *op, NSError *error) {
                    [self handleRequestResult:op];
                }];
                request.requestOperation = operation;
                [_manager.operationQueue addOperation:operation];
            } else {
                request.requestOperation = [_manager GET:url parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self handleRequestResult:operation];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self handleRequestResult:operation];
                }];
            }
        } else if (method == YTKRequestMethodPost) {
            if (constructingBlock != nil) {
                // constructingBlock是一个返回实现AFMultipartFormData协议的对象，该对象主要作用是实现文件上传
                // 我们通常会上传图片或者文件需要用到multipart/form-data，实现以下即可：
                /* 
                 - (AFConstructingBlock)constructingBodyBlock {
                  return ^(id<AFMultipartFormData> formData) {
                    NSData *data = UIImageJPEGRepresentation([UIImage imageNamed:@"currentPageDot"], 0.9);
                    NSString *name = @"image";
                    NSString *formKey = @"image";
                    NSString *type = @"image/jpeg";
                    [formData appendPartWithFileData:data name:formKey fileName:name mimeType:type];
                 };
               }*/
                request.requestOperation = [_manager POST:url parameters:param constructingBodyWithBlock:constructingBlock success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self handleRequestResult:operation];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self handleRequestResult:operation];
                }];
            } else {
                request.requestOperation = [_manager POST:url parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self handleRequestResult:operation];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self handleRequestResult:operation];
                }];
            }
        } else if (method == YTKRequestMethodHead) {
            // 只返回head的请求
            request.requestOperation = [_manager HEAD:url parameters:param success:^(AFHTTPRequestOperation *operation) {
                [self handleRequestResult:operation];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self handleRequestResult:operation];
            }];
        } else if (method == YTKRequestMethodPut) {
            // 更新资源的请求
            request.requestOperation = [_manager PUT:url parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self handleRequestResult:operation];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self handleRequestResult:operation];
            }];
        } else if (method == YTKRequestMethodDelete) {
            // 删除资源
            request.requestOperation = [_manager DELETE:url parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self handleRequestResult:operation];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self handleRequestResult:operation];
            }];
        } else if (method == YTKRequestMethodPatch) {
            // 对PUT请求的补充，更新部分资源
            request.requestOperation = [_manager PATCH:url parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self handleRequestResult:operation];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self handleRequestResult:operation];
            }];
        } else {
            YTKLog(@"Error, unsupport method type");
            return;
        }
    }

    // 添加一个请求到_requestsRecord字典中，key是AFHTTPRequestOperation的hash值，value是YTKBaseRequest对象
    // _requestsRecord的作用：当请求完成时，AFN返回operation，通过_requestsRecord可以反射出它所属的YTKBaseRequest对象
    [self addOperation:request];
}

- (void)cancelRequest:(YTKBaseRequest *)request {
    [request.requestOperation cancel];
    [self removeOperation:request.requestOperation];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    NSDictionary *copyRecord = [_requestsRecord copy];
    for (NSString *key in copyRecord) {
        YTKBaseRequest *request = copyRecord[key];
        [request stop];
    }
}

- (BOOL)checkResult:(YTKBaseRequest *)request {
    // 请求结果code检查
    BOOL result = [request statusCodeValidator];
    if (!result) {
        return result;
    }
    // 请求结果json格式检查
    id validator = [request jsonValidator];
    if (validator != nil) {
        id json = [request responseJSONObject];
        result = [YTKNetworkPrivate checkJson:json withValidator:validator];
    }
    return result;
}

- (void)handleRequestResult:(AFHTTPRequestOperation *)operation {
    // 处理请求结果
    NSString *key = [self requestHashKey:operation];
    // 获取当前请求的request对象
    YTKBaseRequest *request = _requestsRecord[key];
    
    NSString *requestMethod;
    switch (request.requestMethod) {
        case YTKRequestMethodGet: {
            requestMethod = @"Get";
            break;
        }
        case YTKRequestMethodPost: {
            requestMethod = @"Post";
            break;
        }
        case YTKRequestMethodHead: {
            requestMethod = @"Head";
            break;
        }
        case YTKRequestMethodPut: {
            requestMethod = @"Put";
            break;
        }
        case YTKRequestMethodDelete: {
            requestMethod = @"Delete";
            break;
        }
        case YTKRequestMethodPatch: {
            requestMethod = @"Patch";
            break;
        }
    }
    // 打印请求结果，方便调试
    if ([YTKNetworkConfig sharedInstance].requestLogEnabled) {
        if ([requestMethod isEqualToString:@"Get"]) {
            NSLog(@"Finished request: %@ - Method:%@ - Arguments:%@ - Response:%@", [YTKNetworkPrivate urlStringWithOriginUrlString:[self buildRequestUrl:request] appendParameters:request.requestArgument], requestMethod, request.requestArgument, request.responseJSONObject);
        } else {
            NSLog(@"Finished request: %@ - Method:%@ - Arguments:%@ - Response:%@", [self buildRequestUrl:request], requestMethod, request.requestArgument, request.responseJSONObject);
        }
    }
    
    if (request) {
        // 检查请求结果
        BOOL succeed = [self checkResult:request];
        if (succeed) {
            // 调用hook，hook时机：即将完成请求
            [request toggleAccessoriesWillStopCallBack];
            // 通知request内部，请求结束
            [request requestCompleteFilter];
            // 调用请求结束的代理和block（两种回调方式）
            if (request.delegate != nil) {
                [request.delegate requestFinished:request];
            }
            if (request.successCompletionBlock) {
                request.successCompletionBlock(request);
            }
            // 调用hook，hook时机：已经完成请求
            [request toggleAccessoriesDidStopCallBack];
        } else {
            YTKLog(@"Request %@ failed, status code = %ld", NSStringFromClass([request class]), (long)request.responseStatusCode);
            [request toggleAccessoriesWillStopCallBack];
            [request requestFailedFilter];
            if (request.delegate != nil) {
                [request.delegate requestFailed:request];
            }
            if (request.failureCompletionBlock) {
                request.failureCompletionBlock(request);
            }
            [request toggleAccessoriesDidStopCallBack];
        }
    }
    // 请求结束，移除当前operation
    [self removeOperation:operation];
    // 清除回调block，避免循环引用
    [request clearCompletionBlock];
}

- (NSString *)requestHashKey:(AFHTTPRequestOperation *)operation {
    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)[operation hash]];
    return key;
}

- (void)addOperation:(YTKBaseRequest *)request {
    if (request.requestOperation != nil) {
        NSString *key = [self requestHashKey:request.requestOperation];
        // 给self对象创建一个互斥锁，保证此时没有其他对象对self进行修改
        @synchronized(self) {
            _requestsRecord[key] = request;
        }
    }
}

- (void)removeOperation:(AFHTTPRequestOperation *)operation {
    NSString *key = [self requestHashKey:operation];
    @synchronized(self) {
        [_requestsRecord removeObjectForKey:key];
    }
}

@end
