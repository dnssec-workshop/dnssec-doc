Status: {{.Status}}
Message: {{.Message}}
{{range .DomainList}}
Domain name: {{index .name 0}}
Created: {{index .created 0}}
Updated: {{index .updated 0}}

OwnerC Handle: {{index .ownerc_fk 0}}
AdminC Handle: {{index .adminc_fk 0}}
TechC Handle: {{index .techc_fk 0}}
ZoneC Handle: {{index .zonec_fk 0}}

Nameserver:
Nserver1: {{index .nserver1_name 0}} {{index .nserver1_ip 0}}
Nserver2: {{index .nserver2_name 0}} {{index .nserver2_ip 0}}
Nserver3: {{index .nserver3_name 0}} {{index .nserver3_ip 0}}

DNSSEC Key 1 flags: {{index .dnskey1_flags 0}}
DNSSEC Key 1 algorithm_id: {{index .dnskey1_algo 0}}
DNSSEC Key 1 key_data: {{index .dnskey1_key 0}}

DNSSEC Key 2 flags: {{index .dnskey2_flags 0}}
DNSSEC Key 2 algorithm_id: {{index .dnskey2_algo 0}}
DNSSEC Key 2 key_data: {{index .dnskey2_key 0}}
{{end}}
