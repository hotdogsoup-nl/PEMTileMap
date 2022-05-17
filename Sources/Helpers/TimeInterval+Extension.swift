import Foundation

extension TimeInterval{
    func stringValue() -> String {
         let ns = Int((self.truncatingRemainder(dividingBy: 1)) * 1000000000) % 1000
         let us = Int((self.truncatingRemainder(dividingBy: 1)) * 1000000) % 1000
         let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
         let s = Int(self) % 60
         let mn = (Int(self) / 60) % 60
         let hr = (Int(self) / 3600)

         var readableStr = ""
         if hr != 0 {
             readableStr += String(format: "%0.2dhr ", hr)
         }
         if mn != 0 {
             readableStr += String(format: "%0.2dmn ", mn)
         }
         if s != 0 {
             readableStr += String(format: "%0.2ds ", s)
         }
         if ms != 0 {
             readableStr += String(format: "%0.3dms ", ms)
         }
         if us != 0 {
             readableStr += String(format: "%0.3dus ", us)
         }
         if ns != 0 {
             readableStr += String(format: "%0.3dns", ns)
         }

         return readableStr
    }
}
