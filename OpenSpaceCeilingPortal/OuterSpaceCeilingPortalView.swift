//
//  OuterSpaceCeilingPortalView.swift
//  OpenSpaceCeilingPortal
//
//  Created by Matt Pfeiffer on 10/12/24.
//

import ARKit
import RealityKit
import SwiftUI

struct OuterSpaceCeilingPortalView: View {
    @State var detectionTimer: Timer?
    @State var portalEntity: Entity?
    @State var maxRadius: Float = 0
    @State var portalTransform: simd_float4x4?
    @State var animationTimer: Timer?
    @State var portalScale: Float = 0
    
    let session = ARKitSession()
    let planeData = PlaneDetectionProvider(alignments: [.horizontal])
    let detectionDuration: TimeInterval = 2.0
    let portalWorld = Entity()
    let skyboxRadius: Float = 1E3
    let animationDuration: TimeInterval = 5.0
    let updateInterval: TimeInterval = 1/60.0
    
    var body: some View {
        RealityView { content in
            portalWorld.components.set(WorldComponent())
            content.add(portalWorld)
            
            // Create skybox (will be seen through portal)
            do {
                let cgImage = try await downloadImageAndConvertToCGImage()
                let texture = try await TextureResource(image: cgImage, options: .init(semantic: nil))
                let entity = Entity()
                let meshResource = MeshResource.generateSphere(radius: skyboxRadius)
                var material = PhysicallyBasedMaterial()
                material.baseColor.texture = .init(texture)
                let modelComponent = ModelComponent(mesh: meshResource, materials: [material])
                entity.components.set(modelComponent)
                entity.scale *= .init(x: -1, y: 1, z: 1)
                entity.transform.translation += SIMD3<Float>(0.0, 2.0, 0.0)
                portalWorld.addChild(entity)
            } catch {
                print(error)
            }
        } update: { content in
            // add portal once available after detectionDuration
            if let portalEntity = portalEntity {
                if !content.entities.contains(portalEntity) {
                    content.add(portalEntity)
                }
                portalEntity.scale = .one * portalScale
            }
        }
        .task {
            do {
                try await session.run([planeData])
                startDetectionTimer()
                
                for await update in planeData.anchorUpdates {
                    let anchor = update.anchor
                    if anchor.classification == .ceiling {
                        updateMaxRadius(anchor: anchor)
                    }
                }
            } catch {
                print("Error running ARKitSession: \(error)")
            }
        }
        .onDisappear {
            stopDetectionTimer()
            stopAnimationTimer()
        }
    }
    
    // After detectionDuration, stop plane updates and begin animating portal
    private func startDetectionTimer() {
        detectionTimer = Timer.scheduledTimer(withTimeInterval: detectionDuration, repeats: false) { _ in
            session.stop()
            createPortal()
            startAnimationTimer()
        }
    }
    
    private func stopDetectionTimer() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }
    
    private func updateMaxRadius(anchor: PlaneAnchor) {
        let width = anchor.geometry.extent.width
        let height = anchor.geometry.extent.height
        let radius = min(width, height) * 0.8 // leaving padding so we don't extend out of the room
        if radius > maxRadius {
            maxRadius = radius
            portalTransform = anchor.originFromAnchorTransform
        }
    }
    
    private func createPortal() {
        guard let transform = portalTransform else { return }
        
        let entity = Entity()
        entity.setTransformMatrix(transform, relativeTo: nil)
        
        let meshResource = MeshResource.generatePlane(width: maxRadius, depth: maxRadius, cornerRadius: maxRadius * 0.5)
        entity.components.set(
            ModelComponent(
                mesh: meshResource,
                materials: [PortalMaterial()]
            )
        )
        entity.components.set(PortalComponent(target: portalWorld))
        
        portalEntity = entity
        portalWorld.addChild(entity)
    }
    
    private func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            portalScale += Float(updateInterval / animationDuration)
            if portalScale >= 1 {
                portalScale = 1
                stopAnimationTimer()
            }
        }
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    func downloadImageAndConvertToCGImage(from url: URL = URL(string: "https://matt54.github.io/Resources/skybox4.jpg")!) async throws -> CGImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        let image = UIImage(data: data)!
        let cgImage = image.cgImage!
        return cgImage
    }
}
