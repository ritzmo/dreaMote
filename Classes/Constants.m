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

// keys in nsuserdefaults
NSString *kActiveConnection = @"activeConnector";
NSString *kVibratingRC = @"vibrateInRC";
NSString *kConnectionTest = @"connectionTest";
NSString *kMessageTimeout = @"messageTimeout";
NSString *kPrefersSimpleRemote = @"prefersSimpleRemote";