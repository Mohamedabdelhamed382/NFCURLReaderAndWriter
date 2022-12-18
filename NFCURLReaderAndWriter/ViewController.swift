//
//  ViewController.swift
//  NFCURLReaderAndWriter
//
//  Created by MLT on 12/12/2022.
//

import UIKit
import CoreNFC

class ViewController: UIViewController, NFCNDEFReaderSessionDelegate {

    @IBOutlet weak var  urlTextField: UITextField!
    @IBOutlet weak var btnActiveNFC: UIButton!
    var session: NFCNDEFReaderSession?
   // var theActualData = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnActiveNFC.layer.cornerRadius = 5
    }
    
    @IBAction func activateBtn(_ sender: Any) {
//        theActualData = urlTextField.text!
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold Your Near of NFC To Write Code"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        let str:String = "\(urlTextField.text ?? "")"
        if tags.count > 1 {
            let retryInterval = DispatchTimeInterval.microseconds(500)
            session.alertMessage = "more than one tag present, please remove and try again"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
            return
        }
        
        let tag = tags.first!
        session.connect(to: tag) { error in
            
            if nil != error {
                session.alertMessage = "unable to quary the NDEF Status of tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus {(ndefStatus: NFCNDEFStatus, capacity:Int, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "unable to quary the NDEF status of tag."
                    session.invalidate()
                    return
                }
                
                switch ndefStatus {
                case .notSupported:
                    session.alertMessage = "tag is not NDEF Compliant."
                    session.invalidate()
                case .readWrite:
                    tag.writeNDEF(.init(records: [NFCNDEFPayload.wellKnownTypeURIPayload(string: "Https://\(str)")!])) { (error: Error?) in
                        if nil != error {
                            session.alertMessage = "write NDEF message fail: \(String(describing: error))"
                        } else {
                            session.alertMessage = "you have successfully activated your TapTap Card"
                        }
                        session.invalidate()
                    }
                case .readOnly:
                    session.alertMessage = "tag is read only."
                    session.invalidate()
                @unknown default:
                    session.alertMessage = "unknown NDEF tag status."
                    session.invalidate()
                }
            }
        }
//        session.connect(to: tag) { error in
//            if error != nil {
//                session.alertMessage = "unable to connect to Tag"
//                session.invalidate()
//                return
//            }
//
//            tag.queryNDEFStatus { status, capacity, error in
//                guard error == nil else {
//                    session.alertMessage = "unable to quary NDFC status of tag"
//                    session.invalidate()
//                    return
//                }
//
//                switch status {
//                case .notSupported:
//                    session.alertMessage = "Tag is not NDEF Complint"
//                    session.invalidate()
//                case .readWrite:
//                    tag.writeNDEF(.init(records: [NFCNDEFPayload.wellKnownTypeURIPayload(string: str)!])){ error in
//                            if error != nil {
//                                session.alertMessage = "Write NDEF message fail: \(error!)"
//                            } else {
//                                session.alertMessage = "write NDEF Successful"
//                                print("well done")
//                            }
//                            session.invalidate()
//                        }
//
//                case .readOnly:
//                    session.alertMessage = "Tag is read only, is lockd"
//                    session.invalidate()
//                @unknown default:
//                    session.alertMessage = "unkown NDEF tag status"
//                    session.invalidate()
//                }
//
//            }
//        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if(readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertContrllor = UIAlertController(title: "session invaldated", message: error.localizedDescription, preferredStyle: .alert)
                alertContrllor.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertContrllor, animated: true)
                }
            }
        }
    }
}

