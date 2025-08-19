//
//  CameraViewModel.swift
//  打咔 (Daka)
//
//  相机视图模型 - 相机控制与AI处理
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI
import AVFoundation
import Combine

class CameraViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var captureSession = AVCaptureSession()
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var aspectRatio: CameraAspectRatio = .ratio4x3
    @Published var timerMode: CameraTimerMode = .off
    @Published var isFrontCamera = false
    @Published var currentTemplate: PoseTemplate?
    @Published var pipPosition = CGPoint(x: 100, y: 150)
    
    // UI状态
    @Published var showingImagePicker = false
    @Published var showingPreview = false
    @Published var capturedImage: UIImage?
    @Published var isProcessingAI = false
    @Published var processingProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var storageService: StorageService
    private var appViewModel: AppViewModel?
    
    // 服务
    private let cameraService = CameraService()
    private let mediaPipeService = MediaPipeService()
    private let poseGenerationService = PoseGenerationService()
    
    // MARK: - Initialization
    init(storageService: StorageService = StorageService.shared) {
        self.storageService = storageService
        super.init()
        setupCamera()
    }
    
    // MARK: - Public Methods
    
    func onAppear() {
        requestCameraPermission()
    }
    
    func setAppViewModel(_ appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }
    
    func setCurrentTemplate(_ template: PoseTemplate) {
        currentTemplate = template
    }
    
    func clearCurrentTemplate() {
        currentTemplate = nil
    }
    
    func toggleFlashMode() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
    }
    
    func toggleAspectRatio() {
        switch aspectRatio {
        case .ratio4x3:
            aspectRatio = .ratio16x9
        case .ratio16x9:
            aspectRatio = .square
        case .square:
            aspectRatio = .ratio4x3
        }
        updateSessionPreset()
    }
    
    func toggleTimerMode() {
        switch timerMode {
        case .off:
            timerMode = .timer3s
        case .timer3s:
            timerMode = .timer10s
        case .timer10s:
            timerMode = .off
        }
    }
    
    func toggleCamera() {
        sessionQueue.async { [weak self] in
            self?.switchCamera()
        }
    }
    
    func capturePhoto() {
        guard !isLoading else { return }
        
        if timerMode != .off {
            startTimerCapture()
        } else {
            performCapture()
        }
    }
    
    func openImagePicker() {
        showingImagePicker = true
    }
    
    func processSelectedImage(_ image: UIImage) {
        Task {
            await generateTemplateFromImage(image)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        
        // 设置会话预设
        updateSessionPreset()
        
        // 添加视频输入
        addVideoInput()
        
        // 添加照片输出
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            configurePhotoOutput()
        }
        
        captureSession.commitConfiguration()
    }
    
    private func updateSessionPreset() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            let preset: AVCaptureSession.Preset
            switch self.aspectRatio {
            case .ratio4x3:
                preset = .photo
            case .ratio16x9:
                preset = .hd1920x1080
            case .square:
                preset = .photo
            }
            
            if self.captureSession.canSetSessionPreset(preset) {
                self.captureSession.sessionPreset = preset
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    private func addVideoInput() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFrontCamera ? .front : .back) else {
            setError(CameraError.deviceNotFound)
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
        } catch {
            setError(CameraError.inputCreationFailed(error))
        }
    }
    
    private func configurePhotoOutput() {
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
    }
    
    private func switchCamera() {
        guard let currentVideoDevice = videoDeviceInput?.device else { return }
        
        let preferredPosition: AVCaptureDevice.Position = currentVideoDevice.position == .back ? .front : .back
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition) else {
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            captureSession.beginConfiguration()
            
            // 移除当前输入
            if let currentInput = self.videoDeviceInput {
                captureSession.removeInput(currentInput)
            }
            
            // 添加新输入
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    self.isFrontCamera = preferredPosition == .front
                }
            }
            
            captureSession.commitConfiguration()
            
        } catch {
            setError(CameraError.inputCreationFailed(error))
        }
    }
    
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 已授权，启动相机
            sessionQueue.async {
                self.captureSession.startRunning()
            }
        case .notDetermined:
            // 请求权限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.sessionQueue.async {
                        self.captureSession.startRunning()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.setError(CameraError.permissionDenied)
                    }
                }
            }
        case .denied, .restricted:
            setError(CameraError.permissionDenied)
        @unknown default:
            setError(CameraError.permissionDenied)
        }
    }
    
    private func startTimerCapture() {
        let delay = timerMode == .timer3s ? 3.0 : 10.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.performCapture()
        }
    }
    
    private func performCapture() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings.photoCodecType = .hevc
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func generateTemplateFromImage(_ image: UIImage) async {
        isProcessingAI = true
        processingProgress = 0.0
        
        do {
            // 模拟AI处理进度
            for i in 1...10 {
                processingProgress = Double(i) / 10.0
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            }
            
            // 生成姿态模板
            let template = try await poseGenerationService.generateTemplate(from: image)
            
            // 保存模板
            try await storageService.saveUserTemplate(template)
            
            // 设置为当前模板
            await MainActor.run {
                self.currentTemplate = template
                self.appViewModel?.setCurrentTemplate(template)
                self.isProcessingAI = false
            }
            
        } catch {
            await MainActor.run {
                self.setError(error)
                self.isProcessingAI = false
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            setError(CameraError.captureError(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            setError(CameraError.imageProcessingFailed)
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            self.showingPreview = true
        }
    }
}

// MARK: - Camera Errors
enum CameraError: LocalizedError {
    case deviceNotFound
    case permissionDenied
    case inputCreationFailed(Error)
    case captureError(Error)
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "找不到相机设备"
        case .permissionDenied:
            return "相机权限被拒绝"
        case .inputCreationFailed(let error):
            return "创建相机输入失败: \(error.localizedDescription)"
        case .captureError(let error):
            return "拍照失败: \(error.localizedDescription)"
        case .imageProcessingFailed:
            return "图片处理失败"
        }
    }
}