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

const unsigned char SpeechKitApplicationKey[] = {0xda, 0xdb, 0x5a, 0xa1, 0x09, 0x50, 0x7f, 0x1c, 0xfb, 0x52, 0x79, 0xb6, 0x1e, 0x7e, 0x1c, 0x45, 0xdc, 0xb5, 0x59, 0x11, 0xfd, 0xd2, 0x51, 0x58, 0xf5, 0xa7, 0x4c, 0x13, 0x29, 0xa2, 0xbc, 0x03, 0x7e, 0x16, 0xa4, 0x87, 0x67, 0x23, 0xa3, 0x62, 0x75, 0x1c, 0x18, 0x94, 0x9a, 0x34, 0xd9, 0x77, 0xe9, 0x33, 0x88, 0xe6, 0x05, 0xd9, 0x3f, 0xfa, 0x80, 0x8b, 0x0d, 0xa9, 0x2d, 0xc9, 0xac, 0xab};

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
    
    [SpeechKit setupWithID:@"NMDPTRIAL_mlabtechnologies20150120004933" host:@"sslsandbox.nmdp.nuancemobility.net" port:443 useSSL:YES delegate:self];
    
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
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
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"Welcome to Voicepedia.  Please speak your search term after the vibration."];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
    speakIndex = 1;
    shakeIndex = 0;
    
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
    if (speakIndex == 1) {
        SKEndOfSpeechDetection detectionType;
        NSString* recoType;
        recoType = SKDictationRecognizerType;
        detectionType = SKLongEndOfSpeechDetection;
        
        voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        [self.recorder prepareToRecord];
        [self.recorder setMeteringEnabled:YES];
        [self.recorder record];
        
        [self.microphoneImage setHidden:YES];
        [self.waveformView setHidden:NO];
        
        [logoLabel setText:@"Listening"];
    }
    else if (speakIndex == 2) {
        SKEndOfSpeechDetection detectionType;
        NSString* recoType;
        recoType = SKDictationRecognizerType;
        detectionType = SKLongEndOfSpeechDetection;
        
        voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
        
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
        SKEndOfSpeechDetection detectionType;
        NSString* recoType;
        recoType = SKDictationRecognizerType;
        detectionType = SKLongEndOfSpeechDetection;
        
        voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        [self.recorder prepareToRecord];
        [self.recorder setMeteringEnabled:YES];
        [self.recorder record];
        
        [self.microphoneImage setHidden:YES];
        [self.waveformView setHidden:NO];
        
        [logoLabel setText:@"Listening"];
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
    else if (speakIndex == 6) {
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
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSDictionary *pages = [query objectForKey:@"pages"];
        NSDictionary *pageid = [pages objectForKey:idString];
        extract = [pageid objectForKey:@"extract"];
        NSLog(@"URL 3 %@", extract);
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
        for (int i = 0; i < [verbalArray count]; i++) {
            NSString *string = [verbalArray objectAtIndex:i];
            if ([string containsString:recognizedVoice2]) {
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
        NSString *s2 = [s1 stringByReplacingOccurrencesOfString:[sectionsArray objectAtIndex:sectionVal - 1] withString:@""];
        readingSynthesizer = [[AVSpeechSynthesizer alloc]init];
        [readingSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We will begin reading your article section now.  Please shake the device once to pause reading, and a second time to resume.                                           %@", s2]];
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
}

- (void)startListening {
    SKEndOfSpeechDetection detectionType;
    NSString* recoType;
    recoType = SKDictationRecognizerType;
    detectionType = SKLongEndOfSpeechDetection;
    
    voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                           detection:detectionType
                                            language:@"en_US"
                                            delegate:self];
    
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
    completeSectionString = [verbalArray componentsJoinedByString:@","];
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
            recognizedVoice = [results firstResult];
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
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Ok, we won't search for that.  Please speak your new search term after the vibration."];
                if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                    [utterance setRate:0.1];
                } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                    [utterance setRate:0.5];
                }
                [speechSynthesizer speakUtterance:utterance];
            }
        }
        else if (speakIndex == 3) {
            NSLog(@"Third");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.recorder stop];
            [self.microphoneImage setHidden:NO];
            [self.waveformView setHidden:YES];
            recognizedVoice2 = [results firstResult];
            //speakIndex ++;
            NSLog(@"%@", recognizedVoice2);
            if ([recognizedVoice2 containsString:@"Introduction"] || [recognizedVoice2 containsString:@"introduction"]) {
                [self searchWikipedia];
            } else if ([recognizedVoice2 containsString:@"contents"] || [recognizedVoice2 containsString:@"contents"]) {
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

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.recorder stop];
    [self.microphoneImage setHidden:NO];
    [self.waveformView setHidden:YES];
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[error.localizedDescription stringByAppendingString:@".  Please check your internet connection"]];
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
