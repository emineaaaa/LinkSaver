import receive_sharing_intent

/// LinkSaver Share Extension
/// Kullanıcı herhangi bir uygulamadan URL paylaştığında bu sınıf devreye girer.
/// RSIShareViewController tüm iş mantığını (URL yakalama, UserDefaults'a kaydetme,
/// ana uygulamayı açma) otomatik olarak yapar.
class ShareViewController: RSIShareViewController {

    // URL paylaşıldığında ana uygulamaya otomatik yönlendir
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
