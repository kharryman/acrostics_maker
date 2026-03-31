import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  var splashImageView: UIImageView?  // Class-level property

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    GeneratedPluginRegistrant.register(with: self)

    // Create the splash screen image view
    splashImageView = UIImageView(frame: UIScreen.main.bounds)
    splashImageView?.contentMode = .scaleAspectFill

    // Load animation frames
    var images: [UIImage] = []
    for i in 1...7 {
      if let image = UIImage(named: "Splash\(i)") {
        images.append(image)
      }
    }

    splashImageView?.animationImages = images
    splashImageView?.animationDuration = 1.0
    splashImageView?.animationRepeatCount = 1
    splashImageView?.startAnimating()

    // Add splash image view to the main window
    self.window?.addSubview(splashImageView!)

    // Remove splash after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
      self.splashImageView?.removeFromSuperview()
    }

    return result
  }
}
