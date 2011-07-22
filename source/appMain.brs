

Sub Main()

    SetTheme()
    
    m.CaseYears = ["2011", "2010", "2009", "2008", "2007", "2006", "2005", "2004", "2003", "2002", "2001", "2000"]
    
    ShowCategories()


End Sub

Sub SetTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    print "in set theme"
    theme.OverhangOffsetSD_X = "0"
    theme.OverhangOffsetSD_Y = "0"
    theme.OverhangSliceSD = "pkg:/images/overhang_background_sd_720x83.jpg"
    theme.OverhangOffsetHD_Y = "0"
    theme.OverhangOffsetHD_X = "0"
    theme.OverhangSliceHD = "pkg:/images/overhang_background_hd_1281x165.jpg"
    theme.BreadcrumbTextRight = "#FFFFFF"
    theme.BreadcrumbTextLeft = "#FFFFFF"
    theme.BackgroundColor = "#FFFFFF"
    app.SetTheme(theme)

End Sub

Function ShowCategories()
    cats = [{ Title: "Arguments Before the Court",
              ShortDescriptionLine1: "Arguments Before the Court",
              HDPosterUrl: "pkg:/images/category_poster_304x237_arguments.jpg",
              SDPosterUrl: "pkg:/images/category_poster_304x237_arguments.jpg",
            },
            { Title: "Supreme Court Opinions",
              ShortDescriptionLine1: "Supreme Court Opinions",
              HDPosterUrl: "pkg:/images/category_poster_304x237_opinions.jpg",
              SDPosterUrl: "pkg:/images/category_poster_304x237_opinions.jpg",
            }]
    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetListStyle("arced-landscape")
    screen.SetAdUrl("http://sunlightlabs.s3.amazonaws.com/OyezCredit_sd_540X60.jpg", "http://sunlightlabs.s3.amazonaws.com/OyezCredit_728X90.jpg")
    screen.SetAdDisplayMode("scale-to-fill")   
    screen.SetContentList(cats)
    screen.Show()
    while true    
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                if msg.GetIndex() = 0 then
                   FetchContent("arguments")

                elseif msg.GetIndex() = 1 then
                    FetchContent("opinions")
                end if
            end if
        end if
    end while
End Function

Function FetchContent( content_type )
    waitobj = ShowPleaseWait("Retrieving...", "")
    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")

    if content_type = "arguments" then
        name = "Arguments"
        url_suffix = "podcast"
        start_index = 1

    elseif content_type = "opinions" then
        name = "Opinions"
        url_suffix = "podcast-decisions"
        start_index = 2
    endif

    screen.SetMessagePort(port)
    screen.SetListStyle("flat-episodic-16x9")
    screen.SetListNames(m.CaseYears)
    screen.SetBreadcrumbText(name, m.CaseYears[start_index])
    screen.SetFocusedList(start_index)
    args = GetDataByYear(m.CaseYears[start_index], url_suffix)
    if args = invalid then
        args = [{ Title: "None"}]
        screen.SetContentList([{ShortDescriptionLine1:"No Content for this Year"}])
    else
        screen.SetContentList(args)
    endif
    waitobj = invalid
    screen.show()
    focused_item = start_index

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListSelected() then
                if focused_item <> msg.GetIndex() then
                    screen.SetBreadcrumbText(name, m.CaseYears[msg.GetIndex()])
                    waitobj = ShowPleaseWait("Retrieving...", "")
                    args = GetDataByYear(m.CaseYears[msg.GetIndex()], url_suffix)
                    if args <> invalid then 
                        screen.SetContentList(args)
                        screen.SetFocusedListItem(0)
                        waitobj = "nevermind"
                        screen.show()
                    else
                        screen.SetContentList([{ShortDescriptionLine1:"No Content for this Year"}])
                        waitobj = "nevermind"
                        screen.show()
                    endif
                    focused_item = msg.GetIndex()
                endif
            else if msg.isListSelected() then
                print "list selected"
            

            else if msg.isListItemSelected() then
                print "list item selected"
                print msg.GetIndex()
                if args[0].Title <> "None" then
                    print "showing springboard"
                    ShowSpringBoard(args[msg.GetIndex()])
                    
                endif
                
            else if msg.isScreenClosed() then
                return -1
                print "closed"
            endif
           
        endif

    end while

End Function

Function ShowSpringBoard(item)
    waitobj = ShowPleaseWait("Loading...", "")
    springboard = CreateObject("roSpringboardScreen")
    port = CreateObject("roMessagePort")
    springboard.AddButton(1, "Play")
    springboard.SetMessagePort(port)
    springboard.SetContent(item)
    springboard.SetDescriptionStyle("generic")
    springboard.SetPosterStyle("rounded-rect-16x9-generic")
    springboard.SetStaticRatingEnabled(false)
    player = CreateObject("roAudioPlayer")
    waitobj = invalid
    springboard.Show()
    player.SetContentList([item])
    player.SetMessagePort(port)

    while true
        msg = wait(0, port)
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed() then
                return -1
            elseif msg.isButtonPressed() then
                if msg.GetIndex() = 1 then
                    analytics("audiostart-rokusupremecourt", "")
                    player.Play()
                    springboard.ClearButtons()
                    springboard.AddButton(2, "Pause")
                    springboard.Show()

                elseif msg.GetIndex() = 2 then
                    player.Pause()
                    springboard.ClearButtons()
                    springboard.AddButton(3, "Resume")
                    springboard.Show()
                elseif msg.GetIndex() = 3 then
                    player.Resume()        
                    springboard.ClearButtons()
                    springboard.AddButton(2, "Pause")
                    springboard.Show()
                endif
            endif
        endif
    end while

End Function


Function GetDataByYear(year, url_suffix)
        
        url = "www.oyez.org/cases/" + year + "/" + url_suffix
        http = NewHttp(url)
        response = http.GetToStringWithRetry()
        xml = CreateObject("roXMLElement")
        if not xml.Parse(response) then
            print "No Audio Available"
            return invalid
        endif
    
        args = []
        for each item in xml.channel.item
            print item.title.getText()
            obj = { Title : item.title.GetText(),
                    Description : Left(item.description.GetText(), 311),
                    ShortDescriptionLine1: item.title.GetText(),
                   ' ShortDescriptionLine2: item.description.GetText(),
                    Url : item.enclosure@url,
                    StreamFormat : "mp3",
                    ContentType: "audio",
                    SDPosterUrl:"pkg:/images/audio_clip_poster_sd_185x94.jpg",
                    HDPosterUrl:"pkg:/images/full_stream_poster_hd_250x141.jpg"
                    }

            args.Push(obj)
        endfor
        if args.Count() = 0 then 
            print "returning invalid for args"
            return invalid
        else
            return args
        endif
End Function


Function analytics(hit_type, video_id)
    
    utmac = getGAKey()
    utmhn = "roku.sunlightfoundation.com"
    utmn = itostr(rnd(9999999999))
    cookie = itostr(rnd(99999999))
    random_num = itostr(rnd(2147483647))
    todayobj = CreateObject("roDateTime")
    today = itostr(todayobj.getHours() * 60 * 60) + itostr(todayobj.getMinutes() * 60)
    referer = "http://rokudevice.com"
    device_info = CreateObject("roDeviceInfo")
    uservar = "device_id_" + device_info.GetDeviceUniqueId()
    uservar2 = "dt_" + device_info.getdisplayType()  
    uservar3 = "vid_" + video_id
    utmp = "/roku/" + hit_type + "/" + uservar3

    url = HttpEncode("http://www.google-analytics.com/__utm.gif?utmwv=1&utmn="+utmn+"&utmsr=-&utmsc=-&utmul=-&utmje=0&utmfl=-&utmdt=-&utmhn="+utmhn+"&utmr="+referer+"&utmp="+utmp+"&utmac="+utmac+"&utmcc=__utma%3D"+cookie+"."+random_num+"."+today+"."+today+"."+today+".2%3B%2B__utmb%3D"+cookie+"%3B%2B__utmc%3D"+cookie+"%3B%2B__utmz%3D"+cookie+"."+today+".2.2.utmccn%3D(direct)%7Cutmcsr%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D"+cookie+"."+uservar+"%3B"+"."+uservar2+"%3B."+uservar3)

    print "posting to " + url 
    http = NewHttp(url)
    response = http.GetToStringWithRetry()

    
End Function


