//
//  ViewController.m
//  Voice Web Browser
//
//  Created by Michael Royzen on 10/9/15.
//  Copyright © 2015 Michael Royzen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSMutableData *webData;
    NSURLConnection *connection1;
    NSString *recognizedVoice;
    NSString *recognizedVoice2;
    int speakIndex;
    NSString *articleTitleString;
    NSString *idString;
    NSString *extract;
    AVSpeechSynthesizer *readingSynthesizer;
    int shakeIndex;
    int tableIndex;
    NSMutableArray *sectionsArray;
    NSString *completeSectionString;
    AVSpeechSynthesizer *speechSynthesizer2;
    NSString *chosenSection;
    NSString *sectionContent;
    int sectionVal;
    NSMutableArray *verbalArray;
}

@end

const unsigned char SpeechKitApplicationKey[] = {0x41, 0x12, 0xd5, 0x4d, 0xbb, 0x61, 0xc1, 0x0f, 0x30, 0x0a, 0xde, 0xd8, 0x49, 0xe6, 0x27, 0xb9, 0x60, 0x81, 0xad, 0x49, 0x3f, 0x7f, 0x5e, 0x8e, 0xe5, 0x16, 0xa1, 0x8b, 0xa9, 0x3b, 0x3f, 0xea, 0x4d, 0x14, 0x37, 0x08, 0x75, 0xf8, 0x18, 0xa5, 0x02, 0xf6, 0x7d, 0x4c, 0xdc, 0xa5, 0x05, 0x3c, 0x26, 0xb2, 0x85, 0x65, 0x31, 0xe3, 0xf3, 0x17, 0xf9, 0x95, 0xa2, 0xa2, 0xd0, 0xe1, 0x8c, 0x1e};

@implementation ViewController
@synthesize logoLabel;
@synthesize currentWordLabel;

- (void)viewDidLoad {
    [super viewDidLoad];

    GradientView *gradientView = [[GradientView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:gradientView];
    [self.view sendSubviewToBack:gradientView];

    voiceSearch = nil;
    shakeIndex = 0;
    speakIndex = 1;
    tableIndex = 0;
    [readingSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    readingSynthesizer = nil;

    sectionsArray = [[NSMutableArray alloc]init];

    [SpeechKit setupWithID:@"NMDPPRODUCTION_Michael_Royzen_Readr_20150405205027"
                      host:@"dhw.nmdp.nuancemobility.net"
                      port:443
                    useSSL:YES
                  delegate:nil];

    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};

    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];

    self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale currentLocale]];
    self.audioEngine = [[AVAudioEngine alloc] init];

    if (error) {
        AVSpeechSynthesizer *errorSynthesizer = [[AVSpeechSynthesizer alloc] init];

        AVSpeechUtterance *errorUtterance = [[AVSpeechUtterance alloc] initWithString:error.localizedDescription];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [errorUtterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [errorUtterance setRate:0.5];
        }
        [errorSynthesizer speakUtterance:errorUtterance];
    }

    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    [self.waveformView setWaveColor:[UIColor whiteColor]];
    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
    [speechSynthesizer setDelegate:self];
    if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionGranted) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"Welcome to Voicepedia.  Please speak your search term after the vibration."];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:utterance];
        speakIndex = 1;
        shakeIndex = 0;
    } else if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionUndetermined) {
        AVSpeechUtterance *uttterance = [[AVSpeechUtterance alloc] initWithString:@"Welcome to Voicepedia.  To begin searching Wikipedia hands free, please allow access to your device's microphone."];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [uttterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [uttterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:uttterance];
        speakIndex = 0;
    } else if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionDenied) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Welcome to Voicepedia. You cannot search Wikipedia hands free because you have denied access to your device's microphone."];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:utterance];
        speakIndex = 0;
    }

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)updateMeters
{
    CGFloat normalizedValue;
    [self.recorder updateMeters];
    normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.recorder averagePowerForChannel:0]];

    [self.waveformView updateWithLevel:normalizedValue];
}

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }

    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (self.recognitionTask) {
        [self.recognitionTask cancel];
    }

    if (speakIndex == 0) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Thank you for granting microphone access. Please speak your search term after the vibration"];
                if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                    [utterance setRate:0.1];
                } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                    [utterance setRate:0.5];
                }

                [synthesizer speakUtterance:utterance];
                speakIndex = 1;
                shakeIndex = 0;
            }
        }];
    }
    else if (speakIndex == 1) {
        // iOS 9 and earlier code.
        if ([[UIDevice currentDevice] systemVersion].floatValue <= 9.3) {
            SKEndOfSpeechDetection detectionType;
            NSString* recoType;
            recoType = SKDictationRecognizerType;
            detectionType = SKLongEndOfSpeechDetection;

            voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
        } else {
            // iOS 10 code.

            if(self.recognitionTask) {
                [self.recognitionTask cancel];
                self.recognitionTask = nil;
            }

            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
            [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement error:nil];
            [[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

            AVAudioInputNode *inputNode;

            self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            self.recognitionRequest.shouldReportPartialResults = YES;

            self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {

                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                [self.recorder stop];
                [self.microphoneImage setHidden:NO];
                [self.waveformView setHidden:YES];
                recognizedVoice = result.bestTranscription.formattedString;
                NSLog(@"%@", recognizedVoice);
                [self searchWikipedia];

                NSLog(@"Result finalized.");
                [self.audioEngine stop];
                [self.recognitionRequest endAudio];
                [self.audioEngine.inputNode removeTapOnBus:0];

                self.recognitionRequest = nil;
                self.recognitionTask = nil;
            }];

            inputNode = self.audioEngine.inputNode;
            AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
            [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
                [self.recognitionRequest appendAudioPCMBuffer:buffer];
            }];

            [self.audioEngine prepare];

            [self.audioEngine startAndReturnError:nil];
            if(self.audioEngine.isRunning) {
                NSLog(@"The audio engine was started.");
            }
        }
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);


        [self.recorder prepareToRecord];
        [self.recorder setMeteringEnabled:YES];
        [self.recorder record];

        [self.microphoneImage setHidden:YES];
        [self.waveformView setHidden:NO];

        [logoLabel setText:@"Listening"];
    }
    else if (speakIndex == 2) {
        if([[UIDevice currentDevice] systemVersion].floatValue <= 9.3) {
            SKEndOfSpeechDetection detectionType;
            NSString* recoType;
            recoType = SKDictationRecognizerType;
            detectionType = SKLongEndOfSpeechDetection;

            voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                                   detection:detectionType
                                                    language:@"en_US"
                                                    delegate:self];
        } else {
            
            if(self.recognitionTask) {
                [self.recognitionTask cancel];
                self.recognitionTask = nil;
            }
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
            [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement error:nil];
            [[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
            
            AVAudioInputNode *inputNode;
            
            self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            self.recognitionRequest.shouldReportPartialResults = YES;

            self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                [self.recorder stop];
                [self.microphoneImage setHidden:NO];
                [self.waveformView setHidden:YES];
                
                recognizedVoice2 = result.bestTranscription.formattedString;
                speakIndex = 3;
                
                NSLog(@"%@", recognizedVoice2);
                if ([recognizedVoice2 containsString:@"Yes"] || [recognizedVoice2 containsString:@"yes"]) {
                    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
                    [speechSynthesizer setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"Okay.  Do you want to listen to the introduction or the table of contents?"]];
                    //[self searchWikipedia];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer speakUtterance:utterance];
                } else if ([recognizedVoice2 containsString:@"No"] || [recognizedVoice2 containsString:@"no"]) {
                    NSLog(@"The user said no");
                    speakIndex = 1;
                    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
                    [speechSynthesizer setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Ok, we won't read that article.  Please speak your new search term after the vibration."];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer speakUtterance:utterance];
                } else {
                    speakIndex = 2;
                    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
                    [speechSynthesizer setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We're sorry, we didn't catch what you said.  Please try again after the vibration."]];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer speakUtterance:utterance];
                }
                
                NSLog(@"Got the second result.");
                [self.audioEngine stop];
                [self.recognitionRequest endAudio];
                [self.audioEngine.inputNode removeTapOnBus:0];
                if(self.audioEngine.inputNode.numberOfOutputs == 0) {
                    NSLog(@"The deed has been done.");
                } else {
                    NSLog(@"Oh noes there are still busses on this caboose.");
                }
                
                self.recognitionRequest = nil;
                self.recognitionTask = nil;
            }];

            inputNode = self.audioEngine.inputNode;
            AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
            [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
                [self.recognitionRequest appendAudioPCMBuffer:buffer];
            }];
            
            [self.audioEngine prepare];
            
            [self.audioEngine startAndReturnError:nil];
            if(self.audioEngine.isRunning) {
                NSLog(@"The audio engine was started.");
            }
        }

        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);

        [self.recorder prepareToRecord];
        [self.recorder setMeteringEnabled:YES];
        [self.recorder record];

        [self.microphoneImage setHidden:YES];
        [self.waveformView setHidden:NO];

        [logoLabel setText:@"Listening"];
    }
    else if (speakIndex == 3) {
        NSLog(@"Third detect");
        if ([[UIDevice currentDevice] systemVersion].floatValue <= 9.3) {
            SKEndOfSpeechDetection detectionType;
            NSString* recoType;
            recoType = SKDictationRecognizerType;
            detectionType = SKLongEndOfSpeechDetection;

            voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                                   detection:detectionType
                                                    language:@"en_US"
                                                    delegate:self];
        } else {
            if(self.recognitionTask) {
                [self.recognitionTask cancel];
                self.recognitionTask = nil;
            }

            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
            [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement error:nil];
            [[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                                 error:nil];
            AVAudioInputNode *inputNode;

            self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            self.recognitionRequest.shouldReportPartialResults = YES;

            self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {

                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                [self.recorder stop];
                [self.waveformView setHidden:YES];
                [self.microphoneImage setHidden:NO];
                recognizedVoice2 = result.bestTranscription.formattedString;
                
                NSLog(@"%@", recognizedVoice2);
                if ([recognizedVoice2 containsString:@"Introduction"] || [recognizedVoice2 containsString:@"introduction"]) {
                    [self searchWikipedia];
                }
                else if ([recognizedVoice2 containsString:@"Contents"] || [recognizedVoice2 containsString:@"contents"] || [recognizedVoice2 containsString:@"Table"] || [recognizedVoice2 containsString:@"table"]) {
                    NSLog(@"The user said no");
                    speechSynthesizer2 = [[AVSpeechSynthesizer alloc] init];
                    [speechSynthesizer2 setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Ok, we will read the table of contents now."];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer2 speakUtterance:utterance];
                    speakIndex = 26;
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?action=parse&format=json&prop=sections&page=%@&redirects", articleTitleString]];
                    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
                    NSLog(@"URL 5%@", url);
                    connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
                    if(connection1){
                        webData = [[NSMutableData alloc]init];
                    }
                }
                
                NSLog(@"Got the third result");
                [self.audioEngine stop];
                [self.recognitionRequest endAudio];
                if(self.audioEngine.inputNode.numberOfOutputs == 0) {
                    NSLog(@"For the third time, there are no busses on this caboose");
                } else {
                    NSLog(@"For the third time, there are some busses on this caboose");
                }
                    
                self.recognitionRequest = nil;
                self.recognitionTask = nil;
            }];
        
            inputNode = self.audioEngine.inputNode;
            AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
            [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
                [self.recognitionRequest appendAudioPCMBuffer:buffer];
            }];
            
            [self.audioEngine prepare];
            
            [self.audioEngine startAndReturnError:nil];
            if(self.audioEngine.isRunning) {
                NSLog(@"The audio engine was started.");
            }

            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);

            [self.recorder prepareToRecord];
            [self.recorder setMeteringEnabled:YES];
            [self.recorder record];

            [self.microphoneImage setHidden:YES];
            [self.waveformView setHidden:NO];

            [logoLabel setText:@"Listening"];
        }
    }
    else if (speakIndex == 4) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&titles=%@", articleTitleString]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"%@", url);
        connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection1){
            webData = [[NSMutableData alloc]init];
        }
    }
    else if (speakIndex == 5) {

        speakIndex = 6;

        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [self.recorder stop];
        [self.waveformView setHidden:YES];
        [self.microphoneImage setHidden:NO];

        readingSynthesizer = [[AVSpeechSynthesizer alloc] init];
        [readingSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[@"Please shake the device once to pause reading, and a second time to resume.                                           " stringByAppendingString:extract]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [readingSynthesizer speakUtterance:utterance];
    }
    else if (speakIndex == 6 || speakIndex == 29) {
        AVSpeechSynthesizer *synth = [[AVSpeechSynthesizer alloc] init];
        [synth setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"We have finished reading your article.  Please speak your new search term after the vibration."];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [synth speakUtterance:utterance];
        speakIndex = 1;
    }
    else if (speakIndex == 27) {
        [self startListening];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance {
    NSString *labelString = [utterance.speechString substringWithRange:characterRange];
    [currentWordLabel setText:labelString];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"Speech Paused");
    speakIndex = 8;
    shakeIndex = 1;
    /*
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
    [speechSynthesizer setDelegate:self];
    AVSpeechUtterance *utterance2 = [[AVSpeechUtterance alloc]initWithString:@"Paused reading.  If you want to stop, say 'stop' after the vibration.  If you want to resume, shake the device again."];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
        [utterance2 setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance2];
     */
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        NSLog(@"Shake %d", shakeIndex);
        if (speakIndex == 6) {
            [readingSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
            speakIndex++;
        }
        else if (shakeIndex == 1) {
            NSLog(@"ShakeIndex %d", shakeIndex);
            [readingSynthesizer continueSpeaking];
            shakeIndex--;
            speakIndex = 6;
        }
        else if (speakIndex == 29) {
            [readingSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
            speakIndex ++;
        }
        else if (speakIndex == 30) {
            [readingSynthesizer continueSpeaking];
            speakIndex --;
        }
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [webData setLength:0];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [webData appendData:data];
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:error.localizedDescription];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"JSON");
    if (speakIndex == 3 || speakIndex == 1) {
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSArray *arrayOfSearch = [query objectForKey:@"search"];
        NSDictionary *searchDictionary = [arrayOfSearch objectAtIndex:0];
        articleTitleString = [searchDictionary objectForKey:@"title"];
        NSLog(@"%@", articleTitleString);
        articleTitleString = [articleTitleString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        articleTitleString = [articleTitleString stringByReplacingOccurrencesOfString:@"é" withString:@"%E9"];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?action=query&titles=%@&indexpageids=&format=json", articleTitleString]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"URL 1 %@", url);
        connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection1){
            webData = [[NSMutableData alloc]init];
        }
        if (speakIndex == 1) {
            NSLog(@"Recognized the article.");
            NSString *revisedTitleString = [articleTitleString stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
            AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
            [speechSynthesizer setDelegate:self];
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We found an article called %@.  Is this correct?", revisedTitleString]];
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                [utterance setRate:0.1];
            } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                [utterance setRate:0.5];
            }
            [speechSynthesizer speakUtterance:utterance];
        }
        else {
            AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
            [speechSynthesizer setDelegate:self];
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We will read the article intro now."]];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=%@", recognizedVoice]];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
            NSLog(@"URL 4%@", url);
            connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
            if(connection1){
                webData = [[NSMutableData alloc]init];
            }
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                [utterance setRate:0.1];
            } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                [utterance setRate:0.5];
            }
            [speechSynthesizer speakUtterance:utterance];
        }
        speakIndex++;
    }
    else if (speakIndex == 4) {
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSArray *pageids = [query objectForKey:@"pageids"];
        idString= [NSString stringWithFormat:@"%@", [pageids firstObject]];
        speakIndex++;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&titles=%@", articleTitleString]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"URL 2 %@", url);
        NSLog(@"URL 2 %@", articleTitleString);
        connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection1){
            webData = [[NSMutableData alloc]init];
        }
    }
    else if (speakIndex == 5) {
        @try {
            NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
            NSDictionary *query = [allDataDictionary objectForKey:@"query"];
            NSDictionary *pages = [query objectForKey:@"pages"];
            NSDictionary *pageid = [pages objectForKey:idString];
            extract = [pageid objectForKey:@"extract"];
            NSLog(@"URL 3 %@", extract);
        }
        @catch (NSException *exception) {
            AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
            [speechSynthesizer setDelegate:self];
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"We're sorry, the article you named doesn't have an introduction.  Please say the name of a different article after the vibration."];
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                [utterance setRate:0.1];
            } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                [utterance setRate:0.5];
            }
            speakIndex = 1;
            [speechSynthesizer speakUtterance:utterance];
        }
        @finally {

        }
    }
    else if(speakIndex == 26) {
        NSLog(@"Get sections");
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *parse = [allDataDictionary objectForKey:@"parse"];
        NSArray *sections = [parse objectForKey:@"sections"];
        for (NSDictionary *section in sections) {
            NSString *sectionTitle = [section objectForKey:@"line"];
            [sectionsArray addObject:sectionTitle];
        }
        [self readTableOfContents];
    }
    else if (speakIndex == 28) {
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSArray *pageids = [query objectForKey:@"pageids"];
        idString = [NSString stringWithFormat:@"%@", [pageids firstObject]];
        NSLog(@"IDSTRING %@", idString);
        speakIndex++;
        NSString *lowercaseString = [recognizedVoice2 lowercaseString];
        for (int i = 0; i < [verbalArray count]; i++) {
            NSString *string = [verbalArray objectAtIndex:i];
            if ([string containsString:recognizedVoice2] || [string containsString:lowercaseString]) {
                chosenSection = string;
                sectionContent = string;
                sectionVal = i + 1;
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvprop=content&rvsection=%d&titles=%@", sectionVal, articleTitleString]];
                NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
                NSLog(@"URL 5%@", url);
                connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
                if(connection1){
                    webData = [[NSMutableData alloc]init];
                }
                speakIndex = 29;
            }
        }
        if (chosenSection == nil || [chosenSection  isEqual:@""]) {
            AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
            [speechSynthesizer setDelegate:self];
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"We're sorry, the section you named doesn't exist in the article.  Please say the name of a different section after the vibration."];
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                [utterance setRate:0.1];
            } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                [utterance setRate:0.5];
            }
            speakIndex = 27;
            [speechSynthesizer speakUtterance:utterance];
        }
    }
    else if (speakIndex == 29) {
        NSLog(@"Begins parsing %@, %@", sectionContent, idString);
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSDictionary *pages = [query objectForKey:@"pages"];
        NSDictionary *pageid = [pages objectForKey:idString];
        NSArray *revisions = [pageid objectForKey:@"revisions"];
        NSDictionary *first = [revisions objectAtIndex:0];
        sectionContent = [first objectForKey:@"*"];
        NSLog(@"%@", sectionContent);
        NSString *s1 = [sectionContent stringByReplacingOccurrencesOfString:@"=" withString:@""];
        NSString *s2 = [s1 stringByReplacingOccurrencesOfString:@"<ref>" withString:@""];
        NSString *s3 = [s2 stringByReplacingOccurrencesOfString:[sectionsArray objectAtIndex:sectionVal - 1] withString:@""];
        readingSynthesizer = [[AVSpeechSynthesizer alloc]init];
        [readingSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We will begin reading your article section now.  Please shake the device once to pause reading, and a second time to resume.                                           %@", s3]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [readingSynthesizer speakUtterance:utterance];
    }
}


- (void)recognizerDidBeginRecording:(SKRecognizer *)recognizer {
    NSLog(@"Recording started");
    [currentWordLabel setHidden:YES];
}

- (void)recognizerDidFinishRecording:(SKRecognizer *)recognizer {
    NSLog(@"Recording finished");
    [currentWordLabel setText:@""];
    [currentWordLabel setHidden:NO];
}

- (void)startListening {
    if ([[UIDevice currentDevice] systemVersion].floatValue <= 9.3) {
        SKEndOfSpeechDetection detectionType;
        NSString* recoType;
        recoType = SKDictationRecognizerType;
        detectionType = SKLongEndOfSpeechDetection;

        voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
    } else {
        NSError *audioError;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDefaultToSpeaker error:&audioError];
        [[AVAudioSession sharedInstance] setActive:YES error:&audioError];

        SFSpeechAudioBufferRecognitionRequest *recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:recognitionRequest delegate:self];

        [self.audioEngine prepare];

        NSError *error;
        [self.audioEngine startAndReturnError:&error];
        NSLog(@"The audio engine was started");
    }

    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);

    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];

    [self.microphoneImage setHidden:YES];
    [self.waveformView setHidden:NO];

    [logoLabel setText:@"Listening"];
}

- (void)readTableOfContents {
    verbalArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < [sectionsArray count]; i++) {
        [verbalArray addObject:[[NSString stringWithFormat:@"Section %d: ", i + 1] stringByAppendingString:[sectionsArray objectAtIndex:i]]];
    }
    completeSectionString = [verbalArray componentsJoinedByString:@".       "];
    NSLog(@"%@", completeSectionString);
    [self performSelector:@selector(speakTable) withObject:nil afterDelay:3.0];
}

- (void)speakTable {
    if (![speechSynthesizer2 isSpeaking]) {
        AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
        [speechSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"%@.  Which section do you want to listen to?", completeSectionString]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:utterance];
        speakIndex = 27;
    }
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results {
    NSLog(@"Got results");
    NSLog(@"Session ID: [%@].", [SpeechKit sessionID]);

    NSLog(@"%@", [results firstResult]);

    if ([results firstResult] == nil) {
        NSLog(@"Fired %@", [results firstResult]);
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [self.recorder stop];
        [self.microphoneImage setHidden:NO];
        [self.waveformView setHidden:YES];
        recognizedVoice = [results firstResult];
        AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
        [speechSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We're sorry, we didn't catch what you said.  Please try again after the vibration."]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:utterance];
    } else {
        if (speakIndex == 1) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.recorder stop];
            [self.microphoneImage setHidden:NO];
            [self.waveformView setHidden:YES];
            if ([[UIDevice currentDevice] systemVersion].floatValue <= 9.3) {
                recognizedVoice = [results firstResult];
            }
            NSLog(@"%@", recognizedVoice);
            [self searchWikipedia];
            /*
            speakIndex++;
            AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
            [speechSynthesizer setDelegate:self];
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"Do you want to search for %@", recognizedVoice]];
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                [utterance setRate:0.1];
            } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                [utterance setRate:0.5];
            }
            [speechSynthesizer speakUtterance:utterance];
             */
        }
        else if (speakIndex == 2) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.recorder stop];
            [self.microphoneImage setHidden:NO];
            [self.waveformView setHidden:YES];
            recognizedVoice2 = [results firstResult];
            speakIndex = 3;
            NSLog(@"%@", recognizedVoice2);
                if ([recognizedVoice2 containsString:@"Yes"] || [recognizedVoice2 containsString:@"yes"]) {
                    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
                    [speechSynthesizer setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"Okay.  Do you want to listen to the introduction or the table of contents?"]];
                    //[self searchWikipedia];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer speakUtterance:utterance];
                } else if ([recognizedVoice2 containsString:@"No"] || [recognizedVoice2 containsString:@"no"]) {
                    NSLog(@"The user said no");
                    speakIndex = 1;
                    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
                    [speechSynthesizer setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Ok, we won't read that article.  Please speak your new search term after the vibration."];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer speakUtterance:utterance];
                } else {
                    speakIndex = 2;
                    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
                    [speechSynthesizer setDelegate:self];
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We're sorry, we didn't catch what you said.  Please try again after the vibration."]];
                    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                        [utterance setRate:0.1];
                    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                        [utterance setRate:0.5];
                    }
                    [speechSynthesizer speakUtterance:utterance];
                }
        } else if (speakIndex == 3) {
            NSLog(@"Third");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.recorder stop];
            [self.microphoneImage setHidden:NO];
            [self.waveformView setHidden:YES];
            if ([[UIDevice currentDevice] systemVersion].floatValue <= 9.3) {
                recognizedVoice2 = [results firstResult];
            }
            //speakIndex ++;
            NSLog(@"%@", recognizedVoice2);
            if ([recognizedVoice2 containsString:@"Introduction"] || [recognizedVoice2 containsString:@"introduction"]) {
                [self searchWikipedia];
            }
            else if ([recognizedVoice2 containsString:@"contents"] || [recognizedVoice2 containsString:@"Table"] || [recognizedVoice2 containsString:@"table"]) {
                NSLog(@"The user said no");
                speechSynthesizer2 = [[AVSpeechSynthesizer alloc] init];
                [speechSynthesizer2 setDelegate:self];
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Ok, we will read the table of contents now."];
                if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                    [utterance setRate:0.1];
                } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                    [utterance setRate:0.5];
                }
                [speechSynthesizer2 speakUtterance:utterance];
                speakIndex = 26;
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?action=parse&format=json&prop=sections&page=%@&redirects", articleTitleString]];
                NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
                NSLog(@"URL 5%@", url);
                connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
                if(connection1){
                    webData = [[NSMutableData alloc]init];
                }
            }
            else {
                speakIndex = 3;
                AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
                [speechSynthesizer setDelegate:self];
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We're sorry, we didn't catch what you said.  Do you want to listen to the introduction or the table of contents?"]];
                if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                    [utterance setRate:0.1];
                } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                    [utterance setRate:0.5];
                }
                [speechSynthesizer speakUtterance:utterance];
            }
        }
        else if (speakIndex == 27) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.recorder stop];
            [self.microphoneImage setHidden:NO];
            [self.waveformView setHidden:YES];
            recognizedVoice2 = [results firstResult];
            speakIndex ++;
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?action=query&titles=%@&indexpageids=&format=json", articleTitleString]];
            NSLog(@"Article title string %@", articleTitleString);
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
            NSLog(@"%@", url);
            connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
            if(connection1){
                webData = [[NSMutableData alloc]init];
            }
        }
    }

    [logoLabel setText:@"Voicepedia"];
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult {
    NSLog(@"Finished recognizing");
    if(recognitionResult.isFinal) {
        [self.audioEngine stop];
        self.recognitionTask = nil;
    }
    if (recognitionResult.bestTranscription.formattedString == nil) {
        [self.recorder stop];
        [self.microphoneImage setHidden:NO];
        [self.waveformView setHidden:YES];
        recognizedVoice = recognitionResult.bestTranscription.formattedString;
        AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        [speechSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We're sorry, we didn't catch what you said.  Please try again after the vibration."]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
            [utterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:utterance];
    } else {
        if(speakIndex == 1) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.recorder stop];
            [self.microphoneImage setHidden:NO];
            [self.waveformView setHidden:YES];
            recognizedVoice = recognitionResult.bestTranscription.formattedString;
            NSLog(@"%@", recognizedVoice);
            [self searchWikipedia];
        }
    }

    [logoLabel setText:@"Voicepedia"];
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.recorder stop];
    [self.microphoneImage setHidden:NO];
    [self.waveformView setHidden:YES];
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"We can't read your article right now.  Please check your internet connection and make sure microphone access is enabled."];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
}

- (void)searchWikipedia {
    recognizedVoice = [recognizedVoice stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=%@", recognizedVoice]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSLog(@"URL 4%@", url);
    connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    if(connection1){
        webData = [[NSMutableData alloc]init];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
