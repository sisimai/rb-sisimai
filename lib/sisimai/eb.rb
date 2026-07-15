module Sisimai
  # Sisimai::Eb - Package "eb" provides constants for the email bounce.
  module Eb
    #       _       ______
    #   ___| |__   / /  _ \ ___  __ _ ___  ___  _ __
    #  / _ \ '_ \ / /| |_) / _ \/ _` / __|/ _ \| '_ \
    # |  __/ |_) / / |  _ <  __/ (_| \__ \ (_) | | | |
    #  \___|_.__/_/  |_| \_\___|\__,_|___/\___/|_| |_|
    # bounce reason names
    ReAUTH = "AuthFailure"
    ReFAMA = "BadReputation"
    ReBLOC = "Blocked"
    ReBODY = "ContentError"
    ReSENT = "Delivered"
    ReSIZE = "EmailTooLarge"
    ReTIME = "Expired"
    ReTTLS = "FailedSTARTTLS"
    ReFEED = "Feedback"
    ReFILT = "Filtered"
    ReMOVE = "HasMoved"
    ReHOST = "HostUnknown"
    ReFULL = "MailboxFull"
    ReUNIX = "MailerError"
    ReINET = "NetworkError"
    RePASS = "NoRelaying"
    Re00MX = "NotAccept"
    ReNRFC = "NotCompliantRFC"
    Re___1 = "OnHold"
    ReWONT = "PolicyViolation"
    ReFROM = "Rejected"
    ReQPTR = "RequirePTR"
    ReRATE = "RateLimited"
    ReSAFE = "SecurityError"
    ReSPAM = "SpamDetected"
    ReSTOP = "Suppressed"
    ReQUIT = "Suspend"
    ReCOMM = "SyntaxError"
    RePROC = "SystemError"
    ReDISK = "SystemFull"
    Re___0 = "Undefined"
    ReUSER = "UserUnknown"
    ReAWAY = "Vacation"
    ReEXEC = "VirusDetected"

    #       _       ______                                          _
    #   ___| |__   / / ___|___  _ __ ___  _ __ ___   __ _ _ __   __| |
    #  / _ \ '_ \ / / |   / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` |
    # |  __/ |_) / /| |__| (_) | | | | | | | | | | | (_| | | | | (_| |
    #  \___|_.__/_/  \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|
    CeHELO = "HELO"
    CeEHLO = "EHLO"
    CeMAIL = "MAIL"
    CeRCPT = "RCPT"
    CeDATA = "DATA"
    CeQUIT = "QUIT"
    CeRSET = "RSET"
    CeNOOP = "NOOP"
    CeVRFY = "VRFY"
    CeETRN = "ETRN"
    CeEXPN = "EXPN"
    CeHELP = "HELP"
    CeAUTH = "AUTH"
    CeTTLS = "STARTTLS"
    CeXFWD = "XFORWARD"
    CeCONN = "CONN" # CONN is a pseudo SMTP command used only in Sisimai
  end
end

