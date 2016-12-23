require("socket")
require("ssl")
xml=require("xml")

		local http=require'socket.http'
		local https=require'ssl.https'
		requests=require('requests')

		http.timeout=0	


-- tests the functions above
local file = 'dataset.txt'
local outfile = 'expandedDataset.txt'

local file = io.open(file,"r+b")
local outputc = io.open(outfile, "wb")

local domains = [[.ac.ad.ae.aero.af.ag.ai.al.am.an.ao.aq.ar.arpa.as.asia.at.au
.aw.ax.az.ba.bb.bd.be.bf.bg.bh.bi.biz.bj.bm.bn.bo.br.bs.bt.bv.bw.by.bz.ca
.cat.cc.cd.cf.cg.ch.ci.ck.cl.cm.cn.co.com.coop.cr.cs.cu.cv.cx.cy.cz.dd.de
.dj.dk.dm.do.dz.ec.edu.ee.eg.eh.er.es.et.eu.fi.firm.fj.fk.fm.fo.fr.fx.ga
	.gb.gd.ge.gf.gh.gi.gl.gm.gn.gov.gp.gq.gr.gs.gt.gu.gw.gy.hk.hm.hn.hr.ht.hu
	.id.ie.il.im.in.info.int.io.iq.ir.is.it.je.jm.jo.jobs.jp.ke.kg.kh.ki.km.kn
	.kp.kr.kw.ky.kz.la.lb.lc.li.lk.lr.ls.lt.lu.lv.ly.ma.mc.md.me.mg.mh.mil.mk
	.ml.mm.mn.mo.mobi.mp.mq.mr.ms.mt.mu.museum.mv.mw.mx.my.mz.na.name.nato.nc
	.ne.net.nf.ng.ni.nl.no.nom.np.nr.nt.nu.nz.om.org.pa.pe.pf.pg.ph.pk.pl.pm
	.pn.post.pr.pro.ps.pt.pw.py.qa.re.ro.ru.rw.sa.sb.sc.sd.se.sg.sh.si.sj.sk
	.sl.sm.sn.so.sr.ss.st.store.su.sv.sy.sz.tc.td.tel.tf.tg.th.tj.tk.tl.tm.tn
	.to.tp.tr.travel.tt.tv.tw.tz.ua.ug.uk.um.us.uy.va.vc.ve.vg.vi.vn.vu.web.wf
	.ws.xxx.ye.yt.yu.za.zm.zr.zw]]
	function findUrl(textline) 
		local tlds = {}
		for tld in domains:gmatch'%w+' do
			tlds[tld] = true
		end
		local function max4(a,b,c,d) return math.max(a+0, b+0, c+0, d+0) end
		local protocols = {[''] = 0, ['http://'] = 0, ['https://'] = 0, ['ftp://'] = 0}
		local finished = {}
		
		for pos_start, url, prot, subd, tld, colon, port, slash, path in
		textline:gmatch'()(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'
		do
			if protocols[prot:lower()] == (1 - #slash) * #path and not subd:find'%W%W'
			and (colon == '' or port ~= '' and port + 0 < 65536)
			and (tlds[tld:lower()] or tld:find'^%d+$' and subd:find'^%d+%.%d+%.%d+%.$'
			and max4(tld, subd:match'^(%d+)%.(%d+)%.(%d+)%.$') < 256)
			then
				finished[pos_start] = true
				return true,url
			end
		end
		
		for pos_start, url, prot, dom, colon, port, slash, path in
		textline:gmatch'()((%f[%w]%a+://)(%w[-.%w]*)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'
		do
			if not finished[pos_start] and not (dom..'.'):find'%W%W'
			and protocols[prot:lower()] == (1 - #slash) * #path
			and (colon == '' or port ~= '' and port + 0 < 65536)
			then
				return true,url
			end
			
		end
		return false	
	end
	
	function trim(s)
		if not s then return end
		return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
	end
	



	replacePatterns={
["&gt;"] = ">",
["&lt;"] = "<",
["%&nbsp;"]= "	"
}


	function replaceEncoding(line)
		for k,v in pairs(replacePatterns)		do
		line=line:gsub(k,v)
		end
	 return line
	end


	
	printableTagTable={
	["pre" ]=true,
	["b" ]=true,
	["p" ]=true,
	["dd"]=true,
	["h1"]=true,
	["h2"]=true,
	["h3"]=true,
	["h4"]=true,
	["h5"]=true,
	["h6"]=true,
	["li"]=true,
	["div"]=true,
	["span"]=true,
	["a"]=true
	}



	function recursivelyTraverseDonwAndPrint(nodes)
		local resultTable={}
		for name,nodety in pairs(nodes) do
			local node=nodety

			if  type(node)=="string" and printableTagTable[nodes.xml] then
				if node:gsub("%s*","") ~= "" then
					resultTable[#resultTable+1]= node .."\n" 
				end
			end

			if type(node)=="table" then

					tabToMerge=recursivelyTraverseDonwAndPrint( node)
					for i=1, #tabToMerge do
						resultTable[#resultTable+1]= tabToMerge[i]
					end
			end
		end

	return resultTable
	end

	function extractHumanReadableContent(root)
	local	 resultTable={}

		for name,node in pairs(root) do

			if type(node)=="table"  then
				tabToMerge=	recursivelyTraverseDonwAndPrint(node)
				for i=1, #tabToMerge do
						resultTable[#resultTable+1]= tabToMerge[i]
				end
			end

			if type(node)=="string"  and printableTagTable[root.xml]  then
				if node:gsub("%s*","") ~= "" then
					resultTable[#resultTable+1]= node .."\n" 
				end
			end
		end
		
	
		return resultTable
	end

	function expandUrl(url)
	    
		--body,c,l,status = https.request(url)
			print("==============================================================")
		print(url)
		response=requests.get(url)	
		response.text=response.text:gsub("<!%W*%s*%W*>","")
	
		
		if response.text and type(response.text)=="string" then
			response.text= "<root>"..response.text.."</root>"
			
			local body=xml.load(response.text)

			if body  and type(body)== "table" then
	
				return extractHumanReadableContent(body)
			end
		end
			return {[1]= "Error: Could not expand url"}
		
	end
	
	function extractPersona(textLine)
		
		lastPersona="<anonymous>"
		
		for persona in textLine:gmatch("<.+>") do
			lastPersona=persona
		end
		
		return lastPersona
	end
	
	
	if file then

		lineTable={}

		for line in file:lines() do
		
			copystring=line
			outputc.write(outputc,line.."\n")
			
			boolContainsUrl, Url= findUrl(line)
			if boolContainsUrl == true then
				persona=extractPersona(line)
				expandedUrl=expandUrl(Url)
				if expandedUrl and type(expandedUrl)=="table" then
					outputc.write(outputc,"Link expanded from "..persona..Url.."\n")

					for i=1, #expandedUrl do
						outputc.write(outputc,expandedUrl[i].."\n")
						print(expandedUrl[i])
					end
					
				print("==============================================================")
				end
			end
			
		end
		outputc:close()
		
	else
		Spring.Echo(" could not open file")
	end