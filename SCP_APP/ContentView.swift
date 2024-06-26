import SwiftUI
import libssh2

struct ContentView: View {
    @State private var artistName: String = ""
    @State private var songName: String = ""
    @State private var youtubeURL: String = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("アーティスト名", text: $artistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("曲名", text: $songName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("YouTube埋め込みURL", text: $youtubeURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                sendDataToServer()
            }) {
                Text("送信")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    func sendDataToServer() {
        let csvData = "\(artistName),\(songName),\(youtubeURL)\n"
        let fileName = "songs.csv"
        let filePath = NSTemporaryDirectory() + fileName
        let fileURL = URL(fileURLWithPath: filePath)

        do {
            // 既存のファイルに追記するか、新規作成する
            if FileManager.default.fileExists(atPath: filePath) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = csvData.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            // SCPでサーバーにファイルを送信する
            sendFileUsingSCP(fileURL: fileURL)
        } catch {
            print("ファイルの作成または書き込みに失敗しました: \(error.localizedDescription)")
        }
    }

    func sendFileUsingSCP(fileURL: URL) {
        let serverAddress = "your_server_address" // サーバーアドレス
        let username = "your_username"           // ユーザー名
        let password = "your_password"           // パスワード
        let remotePath = "/path/to/remote/directory/songs.csv"

        // SSHセッションの初期化
        libssh2_init(0)
        let session = libssh2_session_init_ex(nil, nil, nil, nil)
        defer { libssh2_session_disconnect(session, "Normal Shutdown"); libssh2_session_free(session) }

        // サーバーへの接続
        let socket = socket(AF_INET, SOCK_STREAM, 0)
        var serverAddr = sockaddr_in()
        serverAddr.sin_family = sa_family_t(AF_INET)
        serverAddr.sin_port = in_port_t(22).bigEndian
        inet_pton(AF_INET, serverAddress, &serverAddr.sin_addr)

        withUnsafePointer(to: &serverAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
                connect(socket, addr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        // SSHハンドシェイク
        libssh2_session_handshake(session, socket)
        libssh2_userauth_password(session, username, password)

        // SCPでファイルを送信
        let localFile = fopen(fileURL.path, "rb")
        defer { fclose(localFile) }

        fseek(localFile, 0, SEEK_END)
        let fileSize = ftell(localFile)
        fseek(localFile, 0, SEEK_SET)

        let scpSession = libssh2_scp_send64(session, remotePath, 0o644, UInt64(fileSize), 0, 0)
        defer { libssh2_channel_free(scpSession) }

        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let bytesRead = fread(&buffer, 1, buffer.count, localFile)
            if bytesRead == 0 { break }
            libssh2_channel_write(scpSession, buffer, bytesRead)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
