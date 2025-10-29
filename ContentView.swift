import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var camera = MetalCamera(shader: fractalEntityShader)
    @State private var pixelBuffer: CVPixelBuffer?
    @State private var permissionGranted = false
    @State private var currentEffect = "Fractals"
    @State private var showMessage = false
    @State private var messageText = ""
    
    let effects = [
        ("Fractals", "🔮", "Mandelbrot fractals & entities"),
        ("Aliens", "👽", "Geometric alien faces"),
        ("Tunnel", "🌈", "Rainbow infinity tunnel"),
        ("Liquid", "💧", "Melting reality"),
        ("Kaleidoscope", "✨", "12-fold mirrors"),
        ("Cosmos", "🌌", "Breathing universe")
    ]
    
    var body: some View {
        ZStack {
            if permissionGranted {
                // Camera View
                MetalView(pixelBuffer: pixelBuffer, pipeline: camera)
                    .ignoresSafeArea()
                
                // Top Bar
                VStack {
                    HStack {
                        // Current Effect Display
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getEffectIcon(currentEffect))
                                .font(.title)
                            Text(currentEffect.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(15)
                        
                        Spacer()
                        
                        // Flip Camera
                        Button(action: {
                            camera.flipCamera()
                            showMessageTemporarily("Camera flipped")
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                
                // Bottom Controls
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Message
                    if showMessage {
                        Text(messageText)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.8))
                            .cornerRadius(25)
                            .transition(.opacity)
                            .padding(.bottom, 10)
                    }
                    
                    // Effect Selector - Scrollable
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(effects, id: \.0) { effect in
                                EffectButton(
                                    name: effect.0,
                                    icon: effect.1,
                                    description: effect.2,
                                    isSelected: currentEffect == effect.0
                                ) {
                                    selectEffect(effect.0)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                    }
                    .background(Color.black.opacity(0.7))
                    
                    // Action Buttons
                    HStack(spacing: 40) {
                        Button(action: {
                            showMessageTemporarily("📸 Captured!")
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .blue, radius: 10)
                        }
                        
                        Button(action: {
                            showMessageTemporarily("🎥 Recording!")
                        }) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, 25)
                    .padding(.bottom, 20)
                }
                
            } else {
                // Permission Screen
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Camera Access Required")
                        .font(.title2)
                    Text("Grant camera permission to experience visual effects")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .onAppear {
            checkCameraPermission()
            camera.onPixelBuffer = { self.pixelBuffer = $0 }
            // Start with first effect
            camera.switchEffect(currentEffect)
        }
    }
    
    // MARK: - Functions
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    permissionGranted = granted
                }
            }
        case .denied, .restricted:
            permissionGranted = false
        @unknown default:
            permissionGranted = false
        }
    }
    
    private func selectEffect(_ effect: String) {
        currentEffect = effect
        camera.switchEffect(effect)
        let icon = getEffectIcon(effect)
        showMessageTemporarily("\(icon) \(effect)")
    }
    
    private func getEffectIcon(_ effect: String) -> String {
        effects.first(where: { $0.0 == effect })?.1 ?? "✨"
    }
    
    private func showMessageTemporarily(_ message: String) {
        messageText = message
        withAnimation {
            showMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showMessage = false
            }
        }
    }
}

// MARK: - Effect Button Component

struct EffectButton: View {
    let name: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 40))
                Text(name)
                    .font(.system(size: 13))
                    .fontWeight(.bold)
                Text(description)
                    .font(.system(size: 9))
                    .opacity(0.8)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.white)
            .frame(width: 110, height: 110)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.purple, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [.gray.opacity(0.3), .black.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.cyan : Color.gray.opacity(0.5), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: isSelected ? .purple.opacity(0.5) : .clear, radius: 15)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}
