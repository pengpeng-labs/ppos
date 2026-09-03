#include <bearssl.h>
#include <stdint.h>

#include "digicert_global_root_g2.h"

static br_x509_trust_anchor ppos_deepseek_anchor;

uint64_t
ppos_deepseek_trust_anchor(void)
{
    ppos_deepseek_anchor.dn.data = digicert_global_root_g2_dn;
    ppos_deepseek_anchor.dn.len = sizeof(digicert_global_root_g2_dn);
    ppos_deepseek_anchor.flags = BR_X509_TA_CA;
    ppos_deepseek_anchor.pkey.key_type = BR_KEYTYPE_RSA;
    ppos_deepseek_anchor.pkey.key.rsa.n = digicert_global_root_g2_rsa_n;
    ppos_deepseek_anchor.pkey.key.rsa.nlen =
        sizeof(digicert_global_root_g2_rsa_n);
    ppos_deepseek_anchor.pkey.key.rsa.e = digicert_global_root_g2_rsa_e;
    ppos_deepseek_anchor.pkey.key.rsa.elen =
        sizeof(digicert_global_root_g2_rsa_e);
    return (uint64_t)(uintptr_t)&ppos_deepseek_anchor;
}
