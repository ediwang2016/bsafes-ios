// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Social
import MobileCoreServices
import BraveShared
import Data

class ShareViewController: SLComposeServiceViewController {
    
    public var pageUrl: URL?
    public var strUrl: String = ""
    public var strTitle: String = ""
    
    lazy var readLaterConfigurationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Read Later"
        // item.value = "add"
        item.tapHandler = self.readLaterConfigurationItemTapped

        return item
    }()
    
    func readLaterConfigurationItemTapped () {
        print("read Later tapped.")
        
//        ReadList.add(self.strTitle, url: self.pageUrl!)
//        DispatchQueue.main.async {
//            ReadList.add(self.strTitle, url: self.pageUrl!)
//        }
        let defaults = UserDefaults(suiteName: "group.brave.mac.local.id")
        defaults?.set(self.strTitle, forKey: "pageTitle")
        defaults?.set(self.pageUrl, forKey: "pageUrl")
        
        readLaterConfigurationItem.title = "Added to Read Later!"
        // self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func urlScheme(for url: String) -> URL? {
        return URL(string: "brave://open-url?url=\(url)")
    }

    override func configurationItems() -> [Any]! {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return []
        }

        // Reduce all input items down to a single list of item providers
        let attachments: [NSItemProvider] = inputItems
            .compactMap { $0.attachments }
            .flatMap { $0 }

        // Look for the first URL the host application is sharing.
        // If there isn't a URL grab the first text item
        guard let provider = attachments.first(where: { $0.isUrl }) ?? attachments.first(where: { $0.isText }) else {
            // If no item was processed. Cancel the share action to prevent the extension from locking the host application
            // due to the hidden ViewController.
            cancel()
            return []
        }

        provider.loadItem(of: provider.isUrl ? kUTTypeURL : kUTTypeText) { item, error in
            var urlItem: URL?

            // We can get urls from other apps as a kUTTypeText type, for example from Apple's mail.app.
            if let text = item as? String {
                urlItem = text.firstURL
            } else if let url = item as? URL {
                urlItem = url.absoluteString.firstURL
            } else {
                self.cancel()
                return
            }

            // Just open the app if we don't find a url. In the future we could
            // use this entry point to search instead of open a given URL
            let urlString = urlItem?.absoluteString ?? ""
            print("Web page url is \(urlString)")
            self.pageUrl = urlItem!
            self.strUrl = urlString

            if let braveUrl = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics).flatMap(self.urlScheme) {
                // self.handleUrl(braveUrl)
            }

            // get the web page title...
            let pageTitle = (self.extensionContext?.inputItems[0] as AnyObject).attributedContentText
            // let pageTitle = inputItems[0].attributedContentText
            print("Web page title is \(pageTitle??.string)")

        }
        
         // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        let configItems = [readLaterConfigurationItem]

        return configItems
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        // remove POST button
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = ""
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.title = "Close"
        
        textView.isEditable = false
        
        // for textView
        func setTextView() {
            var title = textView.text
            self.strTitle = title!
            
            var url = URL(string: self.strUrl)
            var domain = url?.host ?? ""
            
            if title == "" {
                title = domain
            }
            textView.text = title! + "\n\n" + self.strUrl
        }
        
        setTextView()
        
        // style tabke button.
        if let table = textView.superview?.superview?.superview as? UITableView {
            let length = table.numberOfRows(inSection: 0)
            table.scrollToRow(at: IndexPath(row: length - 1, section: 0), at: .bottom, animated: true)

            if let row = table.cellForRow(at: IndexPath(item: 0, section: 0)) as? UITableViewCell {
                row.textLabel?.textColor = UIColor.blue
                row.textLabel?.textAlignment = .center
            }
        }
    }

}

extension NSItemProvider {
    var isText: Bool {
        return hasItemConformingToTypeIdentifier(String(kUTTypeText))
    }
    
    var isUrl: Bool {
        return hasItemConformingToTypeIdentifier(String(kUTTypeURL))
    }
    
    func loadItem(of type: CFString, completion: CompletionHandler?) {
        loadItem(forTypeIdentifier: String(type), options: nil, completionHandler: completion)
    }
}

extension NSObject {
    func callSelector(_ selector: Selector, object: AnyObject?, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Thread.detachNewThreadSelector(selector, toTarget: self, with: object)
        }
    }
}
