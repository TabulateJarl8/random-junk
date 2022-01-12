param(
	[Parameter(HelpMessage="Enable custom config")]
	[switch]$disable = $false,

	[Parameter(HelpMessage="Disable custom config")]
	[switch]$enable = $false
)

if ($enable) {
	# Autohide taskbar
	&{$p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3';$v=(Get-ItemProperty -Path $p).Settings;$v[8]=3;&Set-ItemProperty -Path $p -Name Settings -Value $v}

	# Enable dark mode
	&{$p='HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';&Set-ItemProperty -Path $p -Name AppsUseLightTheme -Value 0}

	&{&Stop-Process -f -ProcessName explorer}
} elseif ($disable) {
	# Don't autohide taskbar
	&{$p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3';$v=(Get-ItemProperty -Path $p).Settings;$v[8]=2;&Set-ItemProperty -Path $p -Name Settings -Value $v}

	# Enable dark mode
	&{$p='HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';&Set-ItemProperty -Path $p -Name AppsUseLightTheme -Value 1}

	&{&Stop-Process -f -ProcessName explorer}
}
