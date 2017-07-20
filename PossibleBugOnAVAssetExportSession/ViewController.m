//
//  ViewController.m
//  PossibleBugOnAVAssetExportSession
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)touchComposeReproducesButton:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ReproducesIssue" ofType:@"mp4"];
    [self composeWithPath:path completion:^{
        [self showAlert];
    }];
}

- (IBAction)touchComposeNotReproducesButton:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"NoIssue" ofType:@"mov"];
    [self composeWithPath:path completion:^{
        [self showAlert];
    }];
}

- (void)showAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Completed"
                                                                       message:@"Expoted to Photo Library"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)composeWithPath:(NSString *)path completion:(void (^)(void))completion
{

    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack* compositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack* videoTrack = [[anAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, anAsset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    [compositionTrack setPreferredTransform:[[[anAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoTrack.naturalSize;
    videoComp.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVMutableVideoCompositionLayerInstruction* layerInstruction =
    [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];

    videoComp.instructions = [NSArray arrayWithObject: instruction];

    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                         presetName:AVAssetExportPresetMediumQuality];
    assetExport.videoComposition = videoComp;

    NSString* videoName = [NSString stringWithFormat:@"%ul.mov", rand()];
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = exportUrl;
    assetExport.shouldOptimizeForNetworkUse = YES;

    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
         if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl])
         {
             [library writeVideoAtPathToSavedPhotosAlbum:exportUrl
                                         completionBlock:^(NSURL *assetURL, NSError *assetError)
              {
                  completion();
                  if (assetError) { }
              }];
         }
     }
     ];
}

@end
