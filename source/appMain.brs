

Sub Main()

    SetTheme()
    
    m.CaseYears = ["2011", "2010", "2009", "2008", "2007", "2006", "2005", "2004", "2003", "2002", "2001", "2000"]
    
    ShowCategories()


End Sub

Sub SetTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    
    theme.OverhangOffsetSD_X = "0"
    theme.OverhangOffsetSD_Y = "0"
    theme.OverhangOffsetHD_Y = "0"
    theme.OverhangOffsetHD_X = "0"
    theme.OverhangSliceHD = "pkg:/images/overhang_background_hd_1281x165.jpg"
    theme.overhandSliceSD = "pjg:/images/overhang_background_sd_720x83.jpg"
    theme.BreadcrumbTextRight = "#E8BB4B"
    theme.BackgroundColor = "#FFFFFF"
    app.SetTheme(theme)

End Sub

Function ShowCategories()
    cats = [{ Title: "Arguments Before the Court",
              HDPosterUrl: "pkg:/images/category_poster_304x237_house.jpg",
              SDPosterUrl: "pkg:/images/category_poster_304x237_house.jpg",
            },
            { Title: "Supreme Court Opinions",
              HDPosterUrl: "pkg:/images/category_poster_304x237_senate.jpg",
              SDPosterUrl: "pkg:/images/category_poster_304x237_senate.jpg",
            }]
    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetListStyle("arced-landscape")
    screen.SetAdUrl("http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/banner_ad_sd_540x60.jpg", "http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/sunlight2_728x90_roku.jpg")
    screen.SetAdDisplayMode("scale-to-fit")   
    screen.SetContentList(cats)
    screen.Show()
    while true    
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                if msg.GetIndex() = 0 then
                   FetchArguments()

                elseif msg.GetIndex() = 1 then
                    FetchOpinions()
                end if
            end if
        end if
    end while

            
                

End Function
Function FetchArguments()
   
    screen = CreateObject("roPosterScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.SetAdUrl("http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/banner_ad_sd_540x60.jpg", "http://assets.sunlightfoundation.com.s3.amazonaws.com/roku/sunlight2_728x90_roku.jpg")
    screen.SetAdDisplayMode("scale-to-fit")    
    screen.SetListNames(m.CaseYears)
    screen.SetBreadcrumbText("Arguments", "")
    args = GetArgumentsByYear(m.CaseYears[0])
    if args = invalid then
        args = [{ Title: "None"}]
        screen.SetContentList([{ShortDescriptionLine1:"No Content for this Year"}])
    endif
    screen.show()

    while true
       msg = wait(0, screen.GetMessagePort())
       if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
                screen.SetBreadcrumbText("Arguments", m.CaseYears[msg.GetIndex()])
                waitobj = ShowPleaseWait("Retrieving Arguments...", "")
                args = GetArgumentsByYear(m.CaseYears[msg.GetIndex()])
                if args <> invalid then 
                    screen.SetContentList(args)
                    waitobj = "nevermind"
                    screen.show()
                else
                    screen.SetContentList([{ShortDescriptionLine1:"No Content for this Year"}])
                    waitobj = "nevermind"
                    screen.show()
                endif

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
            end if
           
        end If

    end while

End Function

Function ShowSpringBoard(item)

    springboard = CreateObject("roSpringboardScreen")
    port = CreateObject("roMessagePort")
    springboard.AddButton(1, "Pause")
    springboard.SetMessagePort(port)
    springboard.SetContent(item)
    springboard.SetProgressIndicatorEnabled(true)
    springboard.SetDescriptionStyle("generic")
    springboard.AllowNavRewind(true)
    springboard.AllowNavFastForward(true)
    player = CreateObject("roAudioPlayer")
    player.SetContentList([item])
    player.SetMessagePort(port)
    waitobj = ShowPleaseWait("Loading...", "")
    player.Play()
    springboard.Show()
    waitobj = "nevermind"
    print item.url
    print item.title

    while true
        msg = wait(0, port)
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed() then
                return -1
            elseif msg.isButtonPressed() then
                if msg.GetIndex() = 1 then
                    player.Pause()
                    springboard.ClearButtons()
                    springboard.AddButton(2, "Resume")
                    springboard.Show()

                elseif msg.GetIndex() = 2 then
                    player.Resume()
                    springboard.ClearButtons()
                    springboard.AddButton(1, "Pause")
                    springboard.Show()
                    
                endif
    
            endif
        
        endif

    end while

End Function


Function GetArgumentsByYear(year)
        
        url = "www.oyez.org/cases/" + year + "/podcast"
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
                    Description : item.description.GetText(),
                    ShortDescriptionLine1: item.title.GetText(),
                    ShortDescriptionLine2: item.description.GetText(),
                    Url : item.enclosure@url,
                    StreamFormat : "mp3",
                    ContentType: "audio",
                    SDPosterUrl:"pkg:/images/video_clip_poster_sd_185x94.jpg",
                    HDPosterUrl:"pkg:/images/video_clip_poster_hd250x141.jpg"
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


