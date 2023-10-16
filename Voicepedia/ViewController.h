//
//  ViewController.h
//  Voice Web Browser
//
//  Created by Michael Royzen on 10/9/15.
//  Copyright © 2015 Michael Royzen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GradientView.h"
#import "SCSiriWaveformView.h"

@interface ViewController : UIViewController <AVSpeechSynthesizerDelegate, NSURLConnectionDataDelegate, SFSpeechRecognitionTaskDelegate> {
    enum {
        TS_IDLE,
        TS_INITIAL,
        TS_RECORDING,
        TS_PROCESSING,
    } transactionState;
}

@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) IBOutlet UIImageView *microphoneImage;
@property (weak, nonatomic) IBOutlet UILabel *currentWordLabel;
@property (strong, nonatomic) IBOutlet GADBannerView *adBannerView;

@property (strong, nonatomic) SFSpeechRecognitionTask *recognitionTask;
@property (strong, nonatomic) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (strong, nonatomic) SFSpeechRecognizer *speechRecognizer;
@property (strong, nonatomic) AVAudioEngine *audioEngine;
@property (strong, nonatomic) NSTimer *speechTimer;
@property (strong, nonatomic) UIImpactFeedbackGenerator *impactGenerator;

@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer2;
@property (strong, nonatomic) AVSpeechSynthesizer *readingSynthesizer;

@end

