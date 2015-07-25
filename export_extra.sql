.mode csv 
.headers on 
.out extra/eps_panel_extra.csv 
select gender,occupation,party,ep_date,name,bio from eps_panel_w_extra;