import UIKit
import AVKit
import AVFoundation
import s2s_sdk_tvos_agent_only

class MovieViewController: UIViewController, Storyboarded {
    
    weak var coordinator: MainCoordinator?
    var detailItem: ContentData?
    var s2sAgent: S2SAgent?
    
    // Movie Player
    var moviePlayerController: AVPlayerViewController!
    var moviePlayer: AVPlayer!
    var moviePlayerItem: AVPlayerItem!
    var videoUrl: URL?
    var offset: Int = 0
    
    private var focusGuide: UIFocusGuide!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = detailItem?.title
        
        focusGuide = UIFocusGuide()
        view.addLayoutGuide(focusGuide)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appWillGoToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        setupMoviePlayer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        moviePlayer.play()
        super.viewWillAppear(animated)
        let menuPressRecognizer = UITapGestureRecognizer()
        menuPressRecognizer.addTarget(self, action: #selector(MovieViewController.menuButtonAction(recognizer:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        self.view.addGestureRecognizer(menuPressRecognizer)
    }
    
    @objc func menuButtonAction(recognizer:UITapGestureRecognizer) {
        s2sAgent?.stop()
        coordinator?.navigationController.popViewController(animated: true)
    }
    
    private func setupMoviePlayer() {
        let onDemandCallback: StreamPositionCallback = { [unowned self] in
            print("Time callback: \(self.moviePlayerItem.currentTime().seconds)")
            return Int64(self.moviePlayerItem.currentTime().seconds * 1000) // we need to return milliseconds
        }

        let liveCallback: StreamPositionCallback = {
            print("Live time callback: \(Date.init().timeIntervalSince1970)")
            return Int64(Date.init().timeIntervalSince1970 * 1000) // we need to return milliseconds
        }
        
        let optin = UserDefaults.standard.bool(forKey: "optin")
        
        if let detail = self.detailItem {
            guard let url: URL = URL(string: detail.urlString) else {
                return
            }
            self.videoUrl = url
            moviePlayerItem = AVPlayerItem(url: url)
            
            do {
                if detail.live {
                    s2sAgent = try S2SAgent(configUrl: "https://demo-config-preproduction.sensic.net/s2s-ios.json", mediaId: "s2sdemomediaid_ssa_ios", optIn: optin, streamPositionCallback: liveCallback)
                } else {
                    s2sAgent = try S2SAgent(configUrl: "https://demo-config-preproduction.sensic.net/s2s-ios.json", mediaId: "s2sdemomediaid_ssa_ios", optIn: optin, streamPositionCallback: onDemandCallback)
                }
            } catch let error {
                print(error)
            }
            
            moviePlayer = AVPlayer(playerItem: moviePlayerItem)

            // setup player
            moviePlayerController = AVPlayerViewController()
            moviePlayerController.player = moviePlayer
            moviePlayerController.showsPlaybackControls = true
            
            moviePlayerController.view.frame = self.view.frame
            
            view.addSubview(moviePlayerController.view)
            view.sendSubviewToBack(moviePlayerController.view)
            addChild(moviePlayerController)
            registerObserver()
            
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(appWillGoToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
    }
    
    private func registerObserver() {
        // observer
        moviePlayer.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        moviePlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        moviePlayer.addObserver(self, forKeyPath: "volume", options: NSKeyValueObservingOptions.new, context: nil)
        moviePlayerController.addObserver(self, forKeyPath: "videoBounds", options: NSKeyValueObservingOptions.new, context: nil)
        
        listenVolumeButton()
    }
    
    private func unregisterObserver() {
        moviePlayerController.view.removeFromSuperview()
        moviePlayerController.removeFromParent()
        moviePlayer.removeObserver(self, forKeyPath: "rate")
        moviePlayer.removeObserver(self, forKeyPath: "status")
        moviePlayer.removeObserver(self, forKeyPath: "volume")
        moviePlayerController.removeObserver(self, forKeyPath: "videoBounds")
        
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.removeObserver(self, forKeyPath: "outputVolume")
    }
    
    private func listenVolumeButton() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("some error")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            guard s2sAgent != nil else {
                return
            }
            let rate = change![NSKeyValueChangeKey.newKey] as! Float
            if rate == 0 {
                s2sAgent?.stop()
            } else {
                if moviePlayer.timeControlStatus == .playing {
                    s2sAgent?.stop()
                }
                sendPlayRequestToAgent()
            }
        }
        if keyPath == "videoBounds" {
            if let rect = change![NSKeyValueChangeKey.newKey] as? CGRect {
                s2sAgent?.screen(screen: rect.debugDescription)
            }
        }
        if keyPath == "status" {
            let statusRaw = change![NSKeyValueChangeKey.newKey] as! Int
            let status = AVPlayer.Status(rawValue: statusRaw)
            if status == AVPlayer.Status.readyToPlay {
                moviePlayerController.showsPlaybackControls = true
            } else {
                print("Error while loading.")
            }
        }
        
        if keyPath == "outputVolume"{
            if let volume = change![NSKeyValueChangeKey.newKey] as? Float {
                s2sAgent?.volume(volume: "\(volume)")
            }
        }
    }
    
    private func sendPlayRequestToAgent() {
        guard let s2sAgent = s2sAgent else {
            return
        }
        let options = ["screen": "Fullscreen", "volume": "\(moviePlayer.volume)", "speed": "\(moviePlayer.rate)"]
        if detailItem!.live {
            s2sAgent.playStreamLive(contentId: detailItem!.contentId, streamStart: "", streamOffset: self.offset, streamId: detailItem!.urlString, options: options, customParams: [:])
            print("play stream live")
        } else {
            s2sAgent.playStreamOnDemand(contentId: detailItem!.contentId,
                                        streamId: detailItem!.urlString,
                                        options: options,
                                        customParams: [:])
            print("play onDemand")
        }
    }
    
    @objc func appWillGoToBackground() {
        s2sAgent?.flushStorageQueue()
    }
    
    // MARK: UIFocusEnvironment
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        /*
            Update the focus guide's `preferredFocusedView` depending on which
            button has the focus.
        */
        guard let nextFocusedView = context.nextFocusedView else { return }

    }
}

