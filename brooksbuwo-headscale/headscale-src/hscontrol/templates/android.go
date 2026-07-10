package templates

import (
	"github.com/chasefleming/elem-go"
)

func Android(url string) *elem.Element {
	return HtmlStructure(
		elem.Title(nil,
			elem.Text("headscale - Android"),
		),
		mdTypesetBody(
			headscaleLogo(),
			H1(elem.Text("Android configuration")),
			H2(elem.Text("GUI")),
			Ol(
				elem.Li(
					nil,
					elem.Text("Install the official Tailscale Android client from the "),
					externalLink("https://play.google.com/store/apps/details?id=com.tailscale.ipn", "Play Store"),
				),
				elem.Li(
					nil,
					elem.Text("Open the "),
					elem.Strong(nil, elem.Text("Tailscale")),
					elem.Text(" app"),
				),
				elem.Li(
					nil,
					elem.Text("Tap "),
					elem.Strong(nil, elem.Text("Get Started")),
					elem.Text(" on the onboarding screen"),
				),
				elem.Li(
					nil,
					elem.Text("Tap "),
					elem.Strong(nil, elem.Text("OK")),
					elem.Text(" on the VPN connection permission dialog"),
				),
				elem.Li(
					nil,
					elem.Text("Close the tailscale.com browser sheet that appears (tap "),
					elem.Strong(nil, elem.Text("X")),
					elem.Text(" in the top-left corner). Do not log in there"),
				),
				elem.Li(
					nil,
					elem.Text("Tap the "),
					elem.Strong(nil, elem.Text("gear icon")),
					elem.Text(" in the top-right corner, then tap "),
					elem.Strong(nil, elem.Text("Accounts")),
				),
				elem.Li(
					nil,
					elem.Text("Tap the "),
					elem.Strong(nil, elem.Text("three-dot menu")),
					elem.Text(" in the top-right corner and select "),
					elem.Strong(nil, elem.Text("Use an auth key")),
				),
				elem.Li(
					nil,
					elem.Text("Paste your pre-authentication key. The device registers automatically"),
				),
			),
			orDivider(),
			H2(elem.Text("Command line")),
			P(
				elem.Text("Use Tailscale's login command to add your profile (requires Tailscale CLI):"),
			),
			Pre(PreCode("tailscale login --login-server "+url)),
			warningBox("Note", "A pre-authentication key is the recommended way to enroll an Android device. Create one in the headscale admin console under Users before starting."),
			pageFooter(),
		),
	)
}
