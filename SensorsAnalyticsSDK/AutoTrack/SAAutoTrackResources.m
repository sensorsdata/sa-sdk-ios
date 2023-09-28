//
// SAAutoTrackResources.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2023/1/16.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAutoTrackResources.h"

@implementation SAAutoTrackResources

+ (NSDictionary *)gestureViewBlacklist {
    static dispatch_once_t onceToken;
    static NSDictionary *info = nil;
    dispatch_once(&onceToken, ^{
        info = @{
            @"public":@[@"UIPageControl",@"UITextField",@"UITextView",@"UITabBar",@"UICollectionView",@"UISearchBar"],
            @"private":@[@"_UIContextMenuContainerView",@"_UIPreviewPlatterView",@"UISwitchModernVisualElement",@"WKContentView",@"UIWebBrowserView"]
        };
    });
    return info;
}

+ (NSDictionary *)viewControllerBlacklist {
    static dispatch_once_t onceToken;
    static NSDictionary *allClasses = nil;
    dispatch_once(&onceToken, ^{
        allClasses = @{
            @"$AppClick":
                @{@"public":@[@"UINavigationController",@"SAAlertController",@"SFSafariViewController",@"AVPlayerViewController",@"UIReferenceLibraryViewController",@"UIImagePickerController",@"UIDocumentMenuViewController",@"UIActivityViewController",@"SLComposeViewController",@"UISplitViewController"],
                  @"private":@[@"SFBrowserRemoteViewController",@"UIInputWindowController",@"UIKeyboardCandidateGridCollectionViewController",@"UICompatibilityInputViewController",@"UIApplicationRotationFollowingControllerNoTouches",@"UIActivityGroupViewController",@"UIKeyboardCandidateRowViewController",@"UIKeyboardHiddenViewController",@"_UIAlertControllerTextFieldViewController",@"_UILongDefinitionViewController",@"_UIResilientRemoteViewContainerViewController",@"_UIShareExtensionRemoteViewController",@"_UIRemoteDictionaryViewController",@"UISystemKeyboardDockController",@"_UINoDefinitionViewController",@"_UIActivityGroupListViewController",@"_UIRemoteViewController",@"_UIFallbackPresentationViewController",@"_UIDocumentPickerRemoteViewController",@"_UIAlertShimPresentingViewController",@"_UIWaitingForRemoteViewContainerViewController",@"_UIActivityUserDefaultsViewController",@"_UIActivityViewControllerContentController",@"_UIRemoteInputViewController",@"_UIUserDefaultsActivityNavigationController",@"_SFAppPasswordSavingViewController",@"UISnapshotModalViewController",@"WKActionSheet",@"DDSafariViewController",@"SFAirDropActivityViewController",@"CKSMSComposeController",@"DDParsecLoadingViewController",@"PLUIPrivacyViewController",@"PLUICameraViewController",@"SLRemoteComposeViewController",@"CAMViewfinderViewController",@"DDParsecNoDataViewController",@"CAMPreviewViewController",@"DDParsecCollectionViewController",@"DDParsecRemoteCollectionViewController",@"AVFullScreenPlaybackControlsViewController",@"PLPhotoTileViewController",@"AVFullScreenViewController",@"CAMImagePickerCameraViewController",@"CKSMSComposeRemoteViewController",@"PUPhotoPickerHostViewController",@"PUUIAlbumListViewController",@"PUUIPhotosAlbumViewController",@"SFAppAutoFillPasswordViewController",@"PUUIMomentsGridViewController",@"SFPasswordRemoteViewController",@"UIWebRotatingAlertController",@"UIEditUserWordController",@"UIActivityContentViewController"]
                },
            @"$AppViewScreen":
                @{@"public":@[@"UIAlertController",@"UITabBarController",@"UINavigationController",@"SAAlertController",@"SFSafariViewController",@"AVPlayerViewController",@"UIReferenceLibraryViewController",@"UIImagePickerController",@"UIDocumentMenuViewController",@"UIActivityViewController",@"SLComposeViewController",@"UISplitViewController",@"UIDocumentPickerViewController",@"UIDocumentBrowserViewController"],
                  @"private":@[@"UIApplicationRotationFollowingController",@"SFBrowserRemoteViewController",@"UIInputWindowController",@"UIKeyboardCandidateGridCollectionViewController",@"UICompatibilityInputViewController",@"UIApplicationRotationFollowingControllerNoTouches",@"UIActivityGroupViewController",@"UIKeyboardCandidateRowViewController",@"UIKeyboardHiddenViewController",@"_UIAlertControllerTextFieldViewController",@"_UILongDefinitionViewController",@"_UIResilientRemoteViewContainerViewController",@"_UIShareExtensionRemoteViewController",@"_UIRemoteDictionaryViewController",@"UISystemKeyboardDockController",@"_UINoDefinitionViewController",@"_UIActivityGroupListViewController",@"_UIRemoteViewController",@"_UIFallbackPresentationViewController",@"_UIDocumentPickerRemoteViewController",@"_UIAlertShimPresentingViewController",@"_UIWaitingForRemoteViewContainerViewController",@"_UIActivityUserDefaultsViewController",@"_UIActivityViewControllerContentController",@"_UIRemoteInputViewController",@"_UIUserDefaultsActivityNavigationController",@"_SFAppPasswordSavingViewController",@"UISnapshotModalViewController",@"WKActionSheet",@"DDSafariViewController",@"SFAirDropActivityViewController",@"CKSMSComposeController",@"DDParsecLoadingViewController",@"PLUIPrivacyViewController",@"PLUICameraViewController",@"SLRemoteComposeViewController",@"CAMViewfinderViewController",@"DDParsecNoDataViewController",@"CAMPreviewViewController",@"DDParsecCollectionViewController",@"DDParsecRemoteCollectionViewController",@"AVFullScreenPlaybackControlsViewController",@"PLPhotoTileViewController",@"AVFullScreenViewController",@"CAMImagePickerCameraViewController",@"CKSMSComposeRemoteViewController",@"PUPhotoPickerHostViewController",@"PUUIAlbumListViewController",@"PUUIPhotosAlbumViewController",@"SFAppAutoFillPasswordViewController",@"PUUIMomentsGridViewController",@"SFPasswordRemoteViewController",@"UIWebRotatingAlertController",@"UIEditUserWordController",@"_UIContextMenuActionsOnlyViewController",@"UIPredictionViewController",@"UISystemInputAssistantViewController",@"UICandidateViewController",@"UIActivityContentViewController",@"SFAirDropViewController",@"_UICursorAccessoryViewController"]
                }
        };
    });
    return allClasses;
}

@end
