import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // EduPulse mobil öncelikli tasarlandı: pencere telefon oranında, ekranın
    // ortasında açılır. Küçük ekranlarda yükseklik görünür alana sığdırılır.
    let visible = (self.screen ?? NSScreen.main)?.visibleFrame ?? self.frame
    let width: CGFloat = 430
    let height: CGFloat = min(920, visible.height - 40)
    let frame = NSRect(
      x: visible.midX - width / 2,
      y: visible.midY - height / 2,
      width: width,
      height: height
    )
    self.setFrame(frame, display: true)
    self.contentMinSize = NSSize(width: 360, height: 600)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
