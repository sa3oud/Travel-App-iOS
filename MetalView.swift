import SwiftUI
import MetalKit
import AVFoundation

struct MetalView: UIViewRepresentable {
    let pixelBuffer: CVPixelBuffer?
    @ObservedObject var pipeline: MetalCamera
    var intensity: Double = 1.0
    var speed: Double = 1.0
    var isPaused: Bool = false
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = pipeline.device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.pixelBuffer = pixelBuffer
        context.coordinator.intensity = Float(intensity)
        context.coordinator.speed = Float(speed)
        context.coordinator.isPaused = isPaused
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var pixelBuffer: CVPixelBuffer?
        var startTime: TimeInterval
        var pausedTime: TimeInterval = 0
        var intensity: Float = 1.0
        var speed: Float = 1.0
        var isPaused: Bool = false
        
        init(_ parent: MetalView) {
            self.parent = parent
            self.startTime = Date().timeIntervalSince1970
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            // Calculate current time with speed multiplier
            var currentTime: Float
            if isPaused {
                currentTime = Float(pausedTime)
            } else {
                let elapsed = Date().timeIntervalSince1970 - startTime
                currentTime = Float(elapsed) * speed
                pausedTime = TimeInterval(currentTime)
            }
            
            var timeUniform = currentTime
            
            // Guard all required resources
            guard let buffer = pixelBuffer,
                  let device = view.device,
                  let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let pipelineState = parent.pipeline.renderPipeline,
                  let texture = buffer.metalTexture(
                    device: device,
                    textureCache: parent.pipeline.textureCache
                  ) else {
                return
            }
            
            // Create command buffer
            guard let commandBuffer = parent.pipeline.commandQueue.makeCommandBuffer() else {
                return
            }
            
            // Create render encoder
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            // Set pipeline state and resources
            encoder.setRenderPipelineState(pipelineState)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.setFragmentBytes(&timeUniform, length: MemoryLayout<Float>.size, index: 0)
            encoder.setFragmentBytes(&intensity, length: MemoryLayout<Float>.size, index: 1)
            
            // Draw full-screen quad
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            
            // End encoding
            encoder.endEncoding()
            
            // Present drawable
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
