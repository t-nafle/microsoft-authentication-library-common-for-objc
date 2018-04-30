// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDAADAuthorizationCodeRequest.h"
#import "MSIDHttpRequest.h"
#import "MSIDAADRequestConfigurator.h"

@implementation MSIDAADAuthorizationCodeRequest

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.requestConfigurator = [MSIDAADRequestConfigurator new];
    }
    return self;
}

- (NSDictionary *)parameters
{
    NSParameterAssert(self.clientId);
    NSParameterAssert(self.redirectUri);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[MSID_OAUTH2_CLIENT_ID] = self.clientId;
    parameters[MSID_OAUTH2_REDIRECT_URI] = self.redirectUri;
    parameters[MSID_OAUTH2_RESPONSE_TYPE] = MSID_OAUTH2_CODE;
    parameters[MSID_OAUTH2_RESPONSE_TYPE] = self.loginHint;
    parameters[@"prompt"] = @"none";
    parameters[MSID_OAUTH2_SCOPE] = self.scope;
    
    return parameters;
}

- (NSURLRequest *)urlRequest
{
    NSParameterAssert(self.endpoint);
    
    NSMutableURLRequest *urlRequest = [[super urlRequest] mutableCopy];
    
    __auto_type urlString = [self.endpoint.absoluteString stringByAppendingString:MSID_OAUTH2_AUTHORIZE_SUFFIX];
    urlRequest.URL = [NSURL URLWithString:urlString];
    urlRequest.HTTPMethod = @"GET";
    
    return urlRequest;
}
@end