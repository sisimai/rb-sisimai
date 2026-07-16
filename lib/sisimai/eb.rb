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

    #       _       ___        _   _
    #   ___| |__   / / \   ___| |_(_) ___  _ __
    #  / _ \ '_ \ / / _ \ / __| __| |/ _ \| '_ \
    # |  __/ |_) / / ___ \ (__| |_| | (_) | | | |
    #  \___|_.__/_/_/   \_\___|\__|_|\___/|_| |_|
    #
    # https://datatracker.ietf.org/doc/html/rfc3464#page-16
    # 2.3.3 Action field
    #   The Action field indicates the action performed by the Reporting-MTA as a result of its attempt
    #   to deliver the message to this recipient address. This field MUST be present for each recipient
    #   named in the DSN.
    #
    #   The syntax for the action-field is:
    #     action-field = "Action" ":" action-value
    #     action-value = "failed" / "delayed" / "delivered" / "relayed" / "expanded"
    #
    #   The action-value may be spelled in any combination of upper and lower case characters.
    #
    #     "failed"    indicates that the message could not be delivered to the recipient.
    #                 The Reporting MTA has abandoned any attempts to deliver the message to this
    #                 recipient. No further notifications should be expected.
    #
    #     "delayed"   indicates that the Reporting MTA has so far been unable to deliver or relay the
    #                 message, but it will continue to attempt to do so. Additional notification
    #                 messages may be issued as the message is further delayed or successfully
    #                 delivered, or if delivery attempts are later abandoned.
    #
    #     "delivered" indicates that the message was successfully delivered to the recipient address
    #                 specified by the sender, which includes "delivery" to a mailing list exploder.
    #                 It does not indicate that the message has been read. This is a terminal state
    #                 and no further DSN for this recipient should be expected.
    #
    #     "relayed"   indicates that the message has been relayed or gatewayed into an environment
    #                 that does not accept responsibility for generating DSNs upon successful delivery.
    #                 This action-value SHOULD NOT be used unless the sender has requested notification
    #                 of successful delivery for this recipient.
    #
    #     "expanded"  indicates that the message has been successfully delivered to the recipient
    #                 address as specified by the sender, and forwarded by the Reporting-MTA beyond
    #                 that destination to multiple additional recipient addresses. An action-value of
    #                 "expanded" differs from "delivered" in that "expanded" is not a terminal state.
    #                 Further "failed" and/or "delayed" notifications may be provided.
    AeFAIL = "failed"
    AeSTAY = "delayed"
    AeSENT = "delivered"
    AePASS = "relayed"
    AeEXPN = "expanded"
  end
end

