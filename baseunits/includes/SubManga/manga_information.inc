function   GetSubMangaInfoFromURL: Byte;
var
  isExtractGenres : Boolean = FALSE;
  s: String;
  i, j  : Cardinal;
begin
  mangaInfo.url:= WebsiteRoots[SUBMANGA_ID,1] + URL;
  if NOT GetPage(TObject(source), mangaInfo.url, Reconnect) then
  begin
    Result:= NET_PROBLEM;
    source.Free;
    exit;
  end;

  // parsing the HTML source
  parse.Clear;
  Parser:= TjsFastHTMLParser.Create(PChar(source.Text));
  Parser.OnFoundTag := OnTag;
  Parser.OnFoundText:= OnText;
  Parser.Exec;

  Parser.Free;
  mangaInfo.website:= WebsiteRoots[SUBMANGA_ID,0];

  mangaInfo.genres:= '';
  mangaInfo.status:= '1';

  // using 1st parser (cover link, summary)
  if parse.Count=0 then exit;
  for i:= 0 to parse.Count-1 do
  begin
    // get manga title
    if (mangaInfo.title = '') AND
       (Pos('content="Leer ', parse.Strings[i]) > 0) then
      mangaInfo.title:= GetString(parse.Strings[i], 'content="Leer ', ' manga online');

    if Pos('class="suscripcion', parse.Strings[i]) > 0 then
    begin
      // get cover link
      if Pos('<img', parse.Strings[i+5]) > 0 then
        mangaInfo.coverLink:= GetAttributeValue(GetTagAttribute(parse.Strings[i+5], 'src'));
      // get summary
      j:= i+8;
      while (j < parse.Count-1) AND (Pos('</p>', parse.Strings[j]) = 0) do
      begin
        Inc(j);
        s:= parse.Strings[j];
        if (s <> '') AND
           (s[1] <> '<') then
        begin
          parse.Strings[j]:= StringFilter(parse.Strings[j]);
          parse.Strings[j]:= StringReplace(parse.Strings[j], #10, '\n', [rfReplaceAll]);
          parse.Strings[j]:= StringReplace(parse.Strings[j], #13, '\r', [rfReplaceAll]);
          mangaInfo.summary:= mangaInfo.summary + parse.Strings[j];
        end;
      end;
    end;

    // get authors/artists
    if (Pos('Creado por', parse.Strings[i])<>0) then
    begin
      if Pos('/autor/', parse.Strings[i+1]) > 0 then
        mangaInfo.authors:= parse.Strings[i+2];
      if Pos('/mangaka/', parse.Strings[i+5]) > 0 then
        mangaInfo.authors:= parse.Strings[i+6];
    end;

    // get genres
    if (Pos('submanga.com/genero/', parse.Strings[i])<>0) then
      mangaInfo.genres:= mangaInfo.genres + parse.Strings[i+1] + ', ';
  end;

  source.Clear;
  if NOT GetPage(TObject(source), mangaInfo.url + '/completa', Reconnect) then
  begin
    Result:= NET_PROBLEM;
    source.Free;
    exit;
  end;

  // parsing the HTML source
  parse.Clear;
  Parser:= TjsFastHTMLParser.Create(PChar(source.Text));
  Parser.OnFoundTag := OnTag;
  Parser.OnFoundText:= OnText;
  Parser.Exec;

  Parser.Free;
  source.Free;

  // using 2nd parser (chapter name and link)
  if parse.Count=0 then exit;
  for i:= 0 to parse.Count-1 do
  begin
    if (Pos('class="s"', parse.Strings[i])>0) AND
       (Pos('</tr>', parse.Strings[i-2])>0) AND
      ((Pos('<tr class="u">', parse.Strings[i-1])>0) OR (Pos('<tr>', parse.Strings[i-1])>0)) AND
      ((Pos('</td>', parse.Strings[i-3])>0) OR (Pos('</th>', parse.Strings[i-3])>0)) then
    begin
      Inc(mangaInfo.numChapter);
      s:= StringReplace(GetAttributeValue(GetTagAttribute(parse.Strings[i+1], 'href')), WebsiteRoots[SUBMANGA_ID,1], '', []);
      for j:= Length(s) downto 1 do
      begin
        if s[j] = '/' then
          break;
      end;
      s:= '/c' + Copy(s, j, Length(s)-j+1);
      mangaInfo.chapterLinks.Add(s);
      s:= RemoveSymbols(TrimLeft(TrimRight(parse.Strings[i+2]))) + ' ' + RemoveSymbols(TrimLeft(TrimRight(parse.Strings[i+4])));
      mangaInfo.chapterName.Add(StringFilter(StringFilter(HTMLEntitiesFilter(s))));
    end;
  end;

  // Since chapter name and link are inverted, we need to invert them
  if mangainfo.ChapterLinks.Count > 1 then
  begin
    i:= 0; j:= mangainfo.ChapterLinks.Count - 1;
    while (i<j) do
    begin
      mangainfo.ChapterName.Exchange(i, j);
      mangainfo.chapterLinks.Exchange(i, j);
      Inc(i); Dec(j);
    end;
  end;
  Result:= NO_ERROR;
end;
