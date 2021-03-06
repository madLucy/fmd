function   GetMangaframeInfoFromURL: Byte;
var
  s: String;
  isExtractChapter: Boolean = FALSE;
  i, j: Cardinal;
begin
  mangaInfo.url:= WebsiteRoots[MANGAFRAME_ID,1] + URL;
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
  source.Free;

  mangaInfo.website:= WebsiteRoots[MANGAFRAME_ID,0];
  mangaInfo.status:= '1';
  mangaInfo.coverLink:= '';
  mangaInfo.summary:= '';
  mangaInfo.authors:= '';
  mangaInfo.artists:= '';
  mangaInfo.genres:= '';

  // using parser (cover link, summary, chapter name and link)
  if parse.Count=0 then exit;
  for i:= 0 to parse.Count-1 do
  begin
    // get chapter name and links
    if (Pos('<div class="list">', parse.Strings[i])>0) then
      isExtractChapter:= TRUE;

    // get manga name
    if (mangaInfo.title = '') AND (Pos(' :: Mangaoku', parse.Strings[i])>0) then
      mangaInfo.title:= GetString('~!@'+parse.Strings[i], '~!@', ' :: Mangaoku');


   { if (isExtractChapter) AND (Pos('</select>', parse.Strings[i])>0) then
      break; }

    if (isExtractChapter) AND
       (Pos('<div class="title">', parse.Strings[i])>0) AND
       (Pos('</div>', parse.Strings[i+2])=0) then
    begin
      Inc(mangaInfo.numChapter);
      s:= StringReplace(GetAttributeValue(GetTagAttribute(parse.Strings[i+1], 'href=')), WebsiteRoots[MANGAFRAME_ID,1], '', []) + 'page/';
      mangaInfo.chapterLinks.Add(s);
      s:= RemoveSymbols(TrimLeft(TrimRight(parse.Strings[i+2])));
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
