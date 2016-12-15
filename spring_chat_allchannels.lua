	local springChatAllChannels = torch.class("neuralconvo.springChatAllChannels")
	local stringx = require "pl.stringx"
	local xlua = require "xlua"

	charackterBlackList={
						["github"]=true,



						}


	function trim(s)
		if not s then return end
		return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
	end

	AllCharacters={}
	characterCounter=0

	local function extractMetaLineFromLog(file)
		local f = assert(io.open(file, 'r'))
		local  Conversations={}
		local Lines={}

		ConversationID=1


		Sstart, Send=0,0
		prevCharacter=""
		lastFoundDiffrentCharacter="Annonymous"


		for line in f:lines() do

			Sstart=string.find(line,"<")
			Send =string.find(line,">")


			if  Sstart and Send then
				Lines[#Lines +1]=	{
									character="empty",
									character2ID = "empty",
									text = "",
									lineID= #Lines,
									boolValidLine= false
									}

	
				character= trim(string.sub(line,Sstart+1,Send-1))
				character2ID = lastFoundDiffrentCharacter

				
				if character == "Nightwatch" then
					character= nil
					Sstart, Send= string.find(line,"<Nightwatch>")
					line= string.sub(line,Send+1, string.len(line))

					Sstart, Send= string.find(line,"<"),string.find(line,">")
					if Sstart and Send then
						character= trim(string.sub(line,Sstart+1,Send-1))

					end
				end

				if character and character ~= ""  then
					--remove the braces
				
					if  AllCharacters[character] == nil then
						--print("New Person:"..character)
						AllCharacters[character]= character
					end

					searchString=string.sub(line,Send+1,string.len(line))

					for dramatispersona,_ in pairs(AllCharacters) do
						if string.lower(dramatispersona) ~= string.lower(character) then
							if string.find(searchString,dramatispersona) then
								character2ID= string.upper(dramatispersona)
							end
						end

					end

						Lines[#Lines]= {
							character=character,
							character2ID = character2ID,
							text = searchString,
							lineID= #Lines,
							boolValidLine= true
						}

						if prevCharacter ~= lastFoundDiffrentCharacter and
							prevCharacter ~= character then
							lastFoundDiffrentCharacter= prevCharacter
						end

						if prevCharacter ~= character then
							prevCharacter = character
						end

				end

			end

			if  string.find(line, "***") ~= nil and #Lines > 0 then
				local Conversation={}
					for i=1, #Lines do
						if Lines[i].boolValidLine == true then
							table.insert(Conversation,Lines[i])
						end
					end

				table.insert(Conversations,Conversation)

				Lines={}
				ConversationID=ConversationID+1
			end
		end

		f:close()
	--	rEchoT(Lines,0)
		return Conversations

	end

	function springChatAllChannels:__init(dir)
		self.dir = dir
	end


	local TOTAL_LINES = 202581

	local function progress(c)
		if c % 10000 == 0 then
			xlua.progress(c, TOTAL_LINES)
		end
	end

	function springChatAllChannels:load()

		 conversations = {}


		print("-- Parsing Chat Dialog data set ...")
		path= self.dir .. "/dataset.txt"
		print(path)

		conversations =extractMetaLineFromLog(path)

		print("Writing Conversation Data Table to file")
		--for i=1, #conversations do
			tablesave(conversations[1], "data/conversations.txt")
		--end


		return conversations
	end

   function exportstring( s )
      return string.format("%q", s)
   end

 function tablesave(  tbl,filename )
       charS,charE = "   ","\n"
       file,err = io.open( filename, "wb" )
      if err then return err end

      -- initiate variables for save procedure
      local tables,lookup = { tbl },{ [tbl] = 1 }
      file:write( "return {"..charE )

      for idx,t in ipairs( tables ) do
         file:write( "-- Table: {"..idx.."}"..charE )
         file:write( "{"..charE )
          thandled = {}

         for i,v in ipairs( t ) do
            thandled[i] = true
            local stype = type( v )
            -- only handle value
            if stype == "table" then
               if not lookup[v] then
                  table.insert( tables, v )
                  lookup[v] = #tables
               end
               file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
               file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
               file:write(  charS..tostring( v )..","..charE )
            end
         end

         for i,v in pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then

               local str = ""
               local stype = type( i )
               -- handle index
               if stype == "table" then
                  if not lookup[i] then
                     table.insert( tables,i )
                     lookup[i] = #tables
                  end
                  str = charS.."[{"..lookup[i].."}]="
               elseif stype == "string" then
                  str = charS.."["..exportstring( i ).."]="
               elseif stype == "number" then
                  str = charS.."["..tostring( i ).."]="
               end

               if str ~= "" then
                  stype = type( v )
                  -- handle value
                  if stype == "table" then
                     if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                     end
                     file:write( str.."{"..lookup[v].."},"..charE )
                  elseif stype == "string" then
                     file:write( str..exportstring( v )..","..charE )
                  elseif stype == "number" then
                     file:write( str..tostring( v )..","..charE )
                  end
               end
            end
         end
         file:write( "},"..charE )
      end
      file:write( "}" )
      file:close()
   end

function stringOfLength(char,length)
	strings=""
	for i=1,length do strings=strings..char end
	return strings
end

