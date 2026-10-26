import Foundation
import UIKit
import AVFoundation

class AudioManager {
    // Shared singleton instance to access audio pipes from anywhere
    static let shared = AudioManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectsPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        configureAudioSession()
    }
    
    /// Prepares Apple's internal hardware mixer for gaming audio parameters
    private func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .gameChat, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🔊 Audio: Failed to configure iOS AVAudioSession: \(error.localizedDescription)")
        }
        #endif
    }
    
    /// Triggers short concurrent audio sound effects from the asset catalog metadata
    func playSFX(named assetName: String, volume: Float = 1.0) {
        // Optimization: Fetch from runtime memory cache map or instantiate if first run
        if let cachedPlayer = soundEffectsPlayers[assetName] {
            if cachedPlayer.isPlaying {
                cachedPlayer.currentTime = 0 // Rewind to start immediately to allow rapid fire spamming
            }
            cachedPlayer.volume = volume
            cachedPlayer.play()
        } else {
            guard let assetData = NSDataAsset(name: assetName) else {
                print("🔊 Audio Warning: Asset \(assetName) not found in Xcassets!")
                return
            }
            
            do {
                let newPlayer = try AVAudioPlayer(data: assetData.data)
                newPlayer.prepareToPlay()
                newPlayer.volume = volume
                soundEffectsPlayers[assetName] = newPlayer
                newPlayer.play()
            } catch {
                print("🔊 Audio Error: Failed to initialize SFX player: \(error.localizedDescription)")
            }
        }
    }
    
    /// Loops an infinite cinematic atmospheric background track seamlessly
    func playBGM(named assetName: String, volume: Float = 0.5) {
        guard let assetData = NSDataAsset(name: assetName) else { return }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(data: assetData.data)
            backgroundMusicPlayer?.numberOfLoops = -1 // Endless looping bound setting
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.volume = volume
            backgroundMusicPlayer?.play()
            print("🎵 Audio: Cinematic Background Music [\(assetName)] tracking engaged.")
        } catch {
            print("🔊 Audio Error: Failed to loop track: \(error.localizedDescription)")
        }
    }
}
