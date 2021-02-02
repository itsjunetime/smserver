import Foundation

func main() {
	let server = ServerDelegate()
	let settings = Settings.shared()
	parseArgs()

	guard !settings.show_help else {
		print(Const.help_string)
		exit(0)
	}

	print(server.startServers() ? "Started server & websocket..." : "Failed to start server and websocket...")

	while let string = readLine() {
		if string == "q" { break }
		else {
			print("got line: \(string)")
		}
	}
}

main()
