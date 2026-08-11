# Stellt die Ausgabekodierung von PowerShell auf UTF-8.
#
# Einbinden mit:  . "$PSScriptRoot\_konsole_utf8.ps1"
#
# Ohne diese Zeile schreibt PowerShell Text mit der Codepage der Konsole, auf
# deutschen Windows-Installationen also 850. Umlaute in unseren Meldungen
# ("übernommen", "läuft") kommen dann im Terminal verstümmelt an, weil dieses
# UTF-8 erwartet.
#
# Wichtig ist die Reihenfolge im Zusammenspiel mit fremden Programmen: flutter
# und ffmpeg schreiben ihre Ausgabe selbst und direkt in die Konsole, solange
# sie nicht durch eine PowerShell-Pipeline laufen. Genau deshalb ruft
# package.ps1 flutter ohne Pipeline und ohne "2>&1" auf. Ginge die Ausgabe
# durch PowerShell, wuerde sie mit der Konsolen-Codepage gelesen und neu
# kodiert - aus "√ Built" wird dabei "ÔêÜ Built".
#
# Hinweis: In einem klassischen Konsolenfenster mit Codepage 850 (statt eines
# UTF-8-Terminals) bleiben Umlaute so oder so unleserlich. Dort hilft nur
# "chcp 65001" oder die Windows-Einstellung "Unicode UTF-8 weltweit".

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
