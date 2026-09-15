" T-SQL (SQL Server / SSMS) reserved keywords.
" Base syntax/sqloracle.vim (loaded by syntax/sql.vim) is Oracle-flavored and
" is missing most of these; add them into its existing highlight groups
" instead of inventing new ones. `syn case ignore` is already set upstream.

syn keyword sqlStatement backup bulk checkpoint dbcc deny deallocate
syn keyword sqlStatement execute exec fetch goto kill merge open
syn keyword sqlStatement print raiserror reconfigure restore restrict
syn keyword sqlStatement return revert setuser shutdown throw
syn keyword sqlStatement close cursor declare use waitfor writetext readtext
syn keyword sqlStatement updatetext dump load try_convert

syn keyword sqlKeyword authorization break browse clustered coalesce
syn keyword sqlKeyword collate compute constraint contained
syn keyword sqlKeyword continue database distributed double dbcc errlvl
syn keyword sqlKeyword external fillfactor foreign freetext freetexttable
syn keyword sqlKeyword holdlock identity identity_insert identitycol nocheck
syn keyword sqlKeyword nonclustered nullif offsets opendatasource openquery
syn keyword sqlKeyword openrowset openxml over percent pivot unpivot plan
syn keyword sqlKeyword proc procedure public replication rowcount
syn keyword sqlKeyword rowguidcol rule save schema securityaudit
syn keyword sqlKeyword semantickeyphrasetable semanticsimilaritydetailstable
syn keyword sqlKeyword semanticsimilaritytable session_user system_user
syn keyword sqlKeyword statistics tablesample textsize top tran transaction
syn keyword sqlKeyword trigger with within external national varying go
syn keyword sqlKeyword current_date current_time current_timestamp
syn keyword sqlKeyword current_user linked nolock readpast readcommitted
syn keyword sqlKeyword readuncommitted repeatableread serializable
syn keyword sqlKeyword rowlock tablock tablockx paglock updlock xlock
syn keyword sqlKeyword output identity_insert

syn keyword sqlOperator all any some between freetext exists
syn match sqlOperator "\<contains\>"
syn keyword sqlOperator is like escape in and or not
syn keyword sqlOperator union intersect except cross apply outer inner
syn keyword sqlOperator left right full join

syn keyword sqlType bigint bit char cursor date datetime datetime2
syn keyword sqlType datetimeoffset decimal float geography geometry
syn keyword sqlType hierarchyid image int money nchar ntext numeric
syn keyword sqlType nvarchar real rowversion smalldatetime smallint
syn keyword sqlType smallmoney sql_variant table time timestamp tinyint
syn keyword sqlType uniqueidentifier varbinary varchar xml

syn keyword sqlStatement while try catch

" OFFSET/FETCH paging, window-function frames, and the trigger pseudo-tables.
syn keyword sqlKeyword offset next only partition range unbounded
syn keyword sqlKeyword preceding following ties recompile maxdop option
syn keyword sqlKeyword sequence synonym columnstore cascade filestream
syn keyword sqlKeyword inserted deleted

syn keyword sqlFunction try_cast try_convert isnull string_agg iif
syn keyword sqlFunction newid isjson json_value json_query
" Date/time
syn keyword sqlFunction dateadd datediff datepart datename getdate
syn keyword sqlFunction getutcdate sysdatetime sysutcdatetime eomonth
syn keyword sqlFunction datefromparts datetimefromparts isdate
" String
syn keyword sqlFunction concat concat_ws string_split string_escape
syn keyword sqlFunction quotename patindex charindex stuff replicate
syn keyword sqlFunction reverse datalength len format
" Window / ranking
syn keyword sqlFunction row_number rank dense_rank ntile lag lead
syn keyword sqlFunction first_value last_value percentile_cont
syn keyword sqlFunction percentile_disc count_big
" Metadata and error handling
syn keyword sqlFunction scope_identity ident_current object_id object_name
syn keyword sqlFunction schema_name db_name suser_sname checksum hashbytes
syn keyword sqlFunction error_message error_number error_severity
syn keyword sqlFunction error_state error_line error_procedure xact_state
syn keyword sqlFunction choose try_parse parse isnumeric

syn match sqlSpecial "@@\w\+"
syn match sqlSpecial "@\w\+"
syn match sqlIdentifier "\[[^][]*\]"
hi def link sqlSpecial Identifier
hi def link sqlIdentifier Identifier
