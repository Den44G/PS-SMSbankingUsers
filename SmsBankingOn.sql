select a.name_cln
from ibank2ua.clients a, ibank2ua.employees b 
where convert(int,channel_perms)&4096 != 0
and a.client_id=b.client_id
and b.status = 2


