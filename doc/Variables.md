This file documents the "SystemVariables" which are used by the
Fountain Registrar to control it's behaviour.

open_registrar
==============

If set to a true value, then when an unknown manufacturer is seen by
the BRSKI voucher-request protocol, a new entry is created in the
manufacturer database, and it is given "firstused" trust.

It will subsequently be found for additional devices that are signed by this
same manufacturer so only one entry will be created.  An administrator can
adopt this manufacturer by changing the trust status.

Certificates (such as that come from devices) contain an indicate of the
Issuer DN signed the certificate, but do not contain the actual public key
of the issuer.  It is therefore impossible to validate a certificate from
an unknown manufacturer without the manufacturer's signing certificate.

The Issuer DN may be able to provide a clue where to look for the certificate
but it's just a heuristic.  A MASA URL in the device certificate would point
toward the manufacturer's web site.


anima_acp
=========

If anima_acp is set, then the Registrar will assign ACP addresses in the
generated certificates.

