import AVFoundation
import MetalKit
import SwiftUI

final class MetalCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private let session = AVCaptureSession()
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    @Published var renderPipeline: MTLRenderPipelineState?
    var textureCache: CVMetalTextureCache?
    private var currentShader: String
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var currentInput: AVCaptureDeviceInput?
    
    var onPixelBuffer: ((CVPixelBuffer) -> Void)?
    
    init(shader: String) {
        self.currentShader = shader
        
        // Safely create Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        
        // Safely create command queue
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = queue
        
        super.init()
        
        // Initialize texture cache
        let result = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            device,
            nil,
            &textureCache
        )
        
        if result != kCVReturnSuccess {
            print("Failed to create texture cache")
        }
        
        makePipeline()
        setupCamera()
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    func reloadShader(_ newShader: String) {
        guard newShader != currentShader else { return }
        self.currentShader = newShader
        makePipeline()
    }
    
    // MARK: - Camera Flip Function
    
    func flipCamera() {
        session.beginConfiguration()
        
        // Remove current input
        if let input = currentInput {
            session.removeInput(input)
        }
        
        // Toggle camera position
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        
        // Get new camera
        guard let newCamera = getCamera(for: currentCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            print("❌ Failed to switch camera")
            session.commitConfiguration()
            return
        }
        
        // Add new input
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentInput = newInput
            print("✅ Camera flipped to: \(currentCameraPosition == .back ? "Back" : "Front")")
        }
        
        session.commitConfiguration()
    }
    
    func switchEffect(_ effectName: String) {
        print("🎨 Switching to effect: \(effectName)")
        
        // Switch between different shaders based on effect name
        let newShader: String
        switch effectName {
        case "Fractals":
            newShader = fractalEntityShader
        case "Aliens":
            newShader = geometricAlienShader
        case "Tunnel":
            newShader = rainbowTunnelShader
        case "Liquid":
            newShader = liquidRealityShader
        case "Kaleidoscope":
            newShader = kaleidoscopeShader
        case "Cosmos":
            newShader = breathingCosmosShader
        default:
            newShader = fractalEntityShader // Default to fractals
        }
        
        reloadShader(newShader)
    }
    
    // MARK: - Private Methods
    
    private func makePipeline() {
        do {
            let library = try device.makeLibrary(source: currentShader, options: nil)
            
            guard let vertex = library.makeFunction(name: "vertexPass"),
                  let fragment = library.makeFunction(name: "fragmentPass") else {
                print("❌ Failed to find Metal functions in shader library")
                return
            }
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            self.renderPipeline = try device.makeRenderPipelineState(descriptor: descriptor)
            print("✅ Metal pipeline created successfully")
            
        } catch {
            print("❌ Failed to create Metal pipeline: \(error)")
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Set session preset
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else {
            session.sessionPreset = .high
        }
        
        // Get camera device
        guard let camera = getCamera(for: currentCameraPosition),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("❌ Failed to get camera device")
            session.commitConfiguration()
            return
        }
        
        // Store current input
        currentInput = input
        
        if session.canAddInput(input) {
            session.addInput(input)
            print("✅ Camera input added")
        }
        
        // Create output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue", qos: .userInteractive))
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            print("✅ Camera output added")
        }
        
        // Set video orientation
        if let connection = output.connection(with: .video) {
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90
                print("✅ Video rotation set to 90°")
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                    print("✅ Video orientation set to portrait")
                }
            }
        }
        
        session.commitConfiguration()
        
        // Start session
        startSession()
        
        print("✅ Camera setup complete")
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Method 1: Try default device
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return camera
        }
        
        // Method 2: Try discovery session
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: position
        )
        
        return discoverySession.devices.first
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.onPixelBuffer?(pixelBuffer)
        }
    }
}

// MARK: - CVPixelBuffer Extension

extension CVPixelBuffer {
    func metalTexture(device: MTLDevice, textureCache: CVMetalTextureCache?) -> MTLTexture? {
        guard let cache = textureCache else {
            return nil
        }
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        var cvTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            cache,
            self,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        guard let metalTexture = cvTexture,
              let texture = CVMetalTextureGetTexture(metalTexture) else {
            return nil
        }
        
        return texture
    }
}
