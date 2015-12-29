Status: {{.Status}}
Message: {{.Message}}

Domain name: {{index .Domain.name 0}}
Created: {{index .Domain.created 0}}
Updated: {{index .Domain.updated 0}}

OwnerC Handle: {{index .Domain.ownerc_fk 0}}
AdminC Handle: {{index .Domain.adminc_fk 0}}
TechC Handle: {{index .Domain.techc_fk 0}}
ZoneC Handle: {{index .Domain.zonec_fk 0}}

Nameserver:
Nserver1: {{index .Domain.nserver1_name 0}} {{index .Domain.nserver1_ip 0}}
Nserver2: {{index .Domain.nserver2_name 0}} {{index .Domain.nserver2_ip 0}}
Nserver3: {{index .Domain.nserver3_name 0}} {{index .Domain.nserver3_ip 0}}

DNSSEC Key 1 flags: {{index .Domain.dnskey1_flags 0}}
DNSSEC Key 1 algorithm_id: {{index .Domain.dnskey1_algo 0}}
DNSSEC Key 1 key_data: {{index .Domain.dnskey1_key 0}}

DNSSEC Key 2 flags: {{index .Domain.dnskey2_flags 0}}
DNSSEC Key 2 algorithm_id: {{index .Domain.dnskey2_algo 0}}
DNSSEC Key 2 key_data: {{index .Domain.dnskey2_key 0}}
