/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that retrieves camera and microphone devices.
*/

import AVFoundation
import Combine

/// An object that retrieves camera and microphone devices.
final class DeviceLookup {
    
    // Discovery sessions to find the front and back cameras, and external cameras in iPadOS.
    private let frontCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let backCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let externalCameraDiscoverSession: AVCaptureDevice.DiscoverySession
    
    init() {
        backCameraDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
                                                                      mediaType: .video,
                                                                      position: .back)
        frontCameraDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                       mediaType: .video,
                                                                       position: .front)
        externalCameraDiscoverSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external],
                                                                         mediaType: .video,
                                                                         position: .unspecified)
       
        AVCaptureDevice.userPreferredCamera = backCameraDiscoverySession.devices.filter{
            return $0.deviceType == .builtInWideAngleCamera
        }.first
        if AVCaptureDevice.userPreferredCamera == nil {
            AVCaptureDevice.userPreferredCamera = backCameraDiscoverySession.devices.first
        }
        logger.info("user preferred camera is \(AVCaptureDevice.userPreferredCamera)")
    }
    
    /// Returns the system-preferred camera for the host system.
    var defaultCamera: AVCaptureDevice {
        get throws {
            guard let videoDevice = AVCaptureDevice.systemPreferredCamera else {
                throw CameraError.videoDeviceUnavailable
            }
            return videoDevice
        }
    }
    
    /// Returns the default microphone for the device on which the app runs.
    var defaultMic: AVCaptureDevice {
        get throws {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                throw CameraError.audioDeviceUnavailable
            }
            return audioDevice
        }
    }
    
    var cameras: [String:AVCaptureDevice] {
        // Populate the cameras array with the available cameras.
        var cameras: [String:AVCaptureDevice] = [:]
        let backCameras = backCameraDiscoverySession.devices
        for camera in backCameras {
            cameras[camera.localizedName] = camera
        }
        
        let frontCameras = frontCameraDiscoverySession.devices
        for camera in frontCameras {
            cameras[camera.localizedName] = camera
        }
        
        // iPadOS supports connecting external cameras.
        let externalCameras = externalCameraDiscoverSession.devices
        for camera in externalCameras {
            cameras[camera.localizedName] = camera
        }
        
        logger.info("available cameras on this system: \(cameras)")
        
#if !targetEnvironment(simulator)
        if cameras.isEmpty {
            fatalError("No camera devices are found on this system.")
        }
#endif
        return cameras
    }
}
