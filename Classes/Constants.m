//
//  Constants.m
//  dreaMote
//
//  Created by Moritz Venn on 16.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

// specific font metrics used in our text fields and text views
NSString *kFontName = @"Arial";

NSString *kVanilla_ID	= @"Vanilla_ID";

// custom notifications
NSString *kReconnectNotification = @"dreaMoteDidReconnect";

// keys in connection dict
NSString *kRemoteName = @"remoteNameKey";
NSString *kRemoteHost = @"remoteHostKey";
NSString *kUsername = @"usernameKey";
NSString *kPassword = @"passwordKey";
NSString *kConnector = @"connectorKey";
NSString *kSingleBouquet = @"singleBouquetKey";
NSString *kPort = @"portKey";
NSString *kAdvancedRemote = @"advancedRemote";
NSString *kSSL = @"ssl";
NSString *kShowNowNext = @"showNowNext";

// keys in nsuserdefaults
NSString *kActiveConnection = @"activeConnector";
NSString *kVibratingRC = @"vibrateInRC";
NSString *kConnectionTest = @"connectionTest";
NSString *kMessageTimeout = @"messageTimeout";
NSString *kPrefersSimpleRemote = @"prefersSimpleRemote";

// shared e2 xml element names
const char *kEnigma2Servicereference = "e2servicereference";
const NSUInteger kEnigma2ServicereferenceLength = 19;
const char *kEnigma2Servicename = "e2servicename";
const NSUInteger kEnigma2ServicenameLength = 14;
const char *kEnigma2Description = "e2description";
const NSUInteger kEnigma2DescriptionLength = 14;
const char *kEnigma2DescriptionExtended = "e2descriptionextended";
const NSUInteger kEnigma2DescriptionExtendedLength = 22;
