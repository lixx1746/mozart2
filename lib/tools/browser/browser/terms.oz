%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  'term' term classes;
%%%  I.e. here all constraint system- depended things are performed
%%  (like 'get a type of a given term', 'parse a term', etc.);
%%%
%%%


local
   MetaTupleTermTermObject
   MetaRecordTermTermObject
   MetaChunkTermTermObject
   %%
   GetListType
   %%
   StripName
   StripBQuotes
   GenVSPrintName
   GenAtomPrintName
   GenNamePrintName
   GenVarPrintName
   GenObjPrintName
   GenClassPrintName
   GenProcPrintName
   GenCellPrintName
   %%
   TupleToList
   SelSubTerms
   IsListDepth   % functional! ... since there is message sending in there;
   LArity
   %%
   TestVarProc
   TestFDVarProc
   TestMetaVarProc
   %%
   GetWFListVar
   %%
   AtomicFilter
   %%
   IsThereAName
   %%
in
   %%
   %%  'Meta' 'term' term object;
   %%
   class MetaTermTermObject
      from UrObject
      %%
      %%
      %% feat
      %% featureName            %  feature in parent record, if any;
      %%
      %%
      %%  Returns a type of given term;
      %%  'Term' is a term to be investigated, 'Self' is 'self' of
      %% calling object, and 'NumberOf' is the sequential number of a given
      %% subterm (our types are not context-free);
      %%
      meth getTermType(Term NumberOf ?Type)
\ifdef DEBUG_TT
         {Show 'MetaTermTermObject::getTermType: ...'}
\endif
         case
            @depth > 1 andthen {self.termsStore canCreateObject($)}
         then
            case {IsVar Term} then
               %% non-monotonic operation;
               %%
               %% relational;
               Type = if {IsRecordCVar Term} then T_ORecord
                      else
                         %% relational;
                         if {IsFdVar Term} then T_FDVariable
                         [] {IsMetaVar Term} then T_MetaVariable
                         else T_Variable
                         fi
                      fi
            else
               case {Value.type Term}
               of atom    then Type = T_Atom
               [] int     then Type = T_Int
               [] float   then Type = T_Float
               [] name    then Type = T_Name
               [] tuple   then
                  local AreVSs in
                     AreVSs = {self.store read(StoreAreVSs $)}
                     %%
                     %% I don't want to reprogram VirtualString.is;
                     if AreVSs = True {VirtualString.is Term True} then
                        Type = T_Atom
                     [] true then   % non-monotonic!!
                        if Term = _|_ then
                           case self.type
                           of !T_List then
                              Type = case NumberOf == 2 then T_List
                                        %%  i.e. this is not-well-formed list;
                                     else {GetListType Term self.store}
                                     end
                           else Type = {GetListType Term self.store}
                           end
                        else
                           case {Label Term} == '#' andthen {Width Term} > 1
                           then Type = T_HashTuple
                           else Type = T_Tuple
                           end
                        end
                     end
                  end
               [] procedure then
                  Type = case {Object.is Term} then T_Object
                         else T_Procedure
                         end
               [] cell then Type = T_Cell
               [] record then
                  Type = case {Class.is Term} then T_Class
                         else T_Record
                         end
               else
                  {BrowserWarning ['Oz Term of unknown type: ' Term]}
                  Type = T_Unknown
               end
            end
         else
            Type = T_Shrunken
         end
      end
      %%
      %%  Yields 'True' if referenced 'self' (i.e. 'RN=<term>')
      %% should be enclosed in (round) braces (i.e. '(RN=<term>)');
      meth needsBracesRef(?Needs)
\ifdef DEBUG_TT
         {Show 'MetaTermTermObject::needsBracesRef: ...'}
\endif
         Needs = case self.parentObj.type
                 of !T_PSTerm     then False
                 [] !T_Atom       then False
                 [] !T_Int        then False
                 [] !T_Float      then False
                 [] !T_Name       then False
                 [] !T_Procedure  then False
                 [] !T_Cell       then False
                 [] !T_Object     then False
                 [] !T_Class      then False
                 [] !T_WFList     then False
                 [] !T_Tuple      then False
                 [] !T_Record     then False
                 [] !T_ORecord    then False
                 [] !T_List       then True
                 [] !T_FList      then True
                 [] !T_HashTuple  then True
                 [] !T_Variable   then False
                 [] !T_FDVariable then False
                 [] !T_MetaVariable then False
                 [] !T_Shrunken   then False
                 [] !T_Reference  then False
                 [] !T_Unknown    then False
                 else
                    {BrowserWarning
                     ['Unknown type in TermObject::needsBracesRef: '
                        self.parentObj.type]}
                    False
                 end
         %%
      end
      %%
      %%
      meth genLitPrintName(Lit ?PName)
         %%
         PName = case {IsAtom Lit} then {GenAtomPrintName Lit}
                 else {GenNamePrintName Lit self.store}
                 end
      end
      %%
      %%
      %%  default 'areCommas' - there are no commas;
      meth areCommas(?AreCommas)
         AreCommas = False
      end
      %%
      %%
      %% meth setFeatureName(Feature)
      %% self.featureName = Feature
      %% end
      %%
   end
   %%
   %%
   %%  Atoms;
   %%
   class AtomTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
      %%
      %%
      %%  We need 'setName' here and for 'RecordTermTermObject', since
      %% it's redefined for chunk objects;
      %%
      meth setName
         local AreVSs Name in
            AreVSs = {self.store read(StoreAreVSs $)}
            %%
            Name = case AreVSs then {GenVSPrintName self.term}
                   else {GenAtomPrintName self.term}
                   end
            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>
         end
      end
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'AtomTermTermObject::initTerm is applied'#self.term}
\endif
         <<setName>>
      end
   end
   %%
   %%  Integers;
   %%
   class IntTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'IntTermTermObject::initTerm is applied'#self.term}
\endif
         local AreVSs Name in
            AreVSs = {self.store read(StoreAreVSs $)}
            %%
            Name = case AreVSs then {GenVSPrintName self.term}
                   else {VirtualString.changeSign self.term "~"}
                   end
            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>
         end
      end
   end
   %%
   %%  Floats;
   %%
   class FloatTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'FloatTermTermObject::initTerm is applied'#self.term}
\endif
         local AreVSs Name in
            AreVSs = {self.store read(StoreAreVSs $)}
            %%
            Name = case AreVSs then {GenVSPrintName self.term}
                        else {VirtualString.changeSign self.term "~"}
                        end
            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>
         end
      end
   end
   %%
   %%  Names;
   %%
   class NameTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'NameTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Name in
            Term = self.term
            %%
            Name = case {Bool.is Term} then
                      case Term then "<B: true>" else "<B: false>" end
                   else {GenNamePrintName Term self.store}
                   end
            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>
         end
      end
   end
   %%
   %%
   %%  Generic compound (tuple-like) objects;
   %%
   class MetaTupleTermTermObject
      from MetaTermTermObject
      %%
      %%
      %%  Create additional subterm objects from the number StartNum;
      %%  This is implemented for flat lists and open feature structures;
      %%
      %%  'StartNum' is the number of the first new subterm;
      %%  'NumReuse' is the number of subterms those slots (subterm records)
      %% can be reused (typically one, since by extension we remove only
      %% a tail variable);
      %%
      meth initMoreSubterms(StartNum NumReuse SubsList ?EndNum)
\ifdef DEBUG_TT
         {Show 'MetaTupleTermTermObject::initMoreSubterms '#
          self.term#StartNum#NumReuse#SubsList}
\endif
         local SWidth TWidth NumOfNew in
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Length SubsList} + StartNum - 1
            %%
            case SWidth < TWidth then
               %%
               NumOfNew = SWidth - StartNum + 1 - NumReuse
               case NumOfNew > 0 then
                  %%
                  %% we have really to add something;
                  EndNum = SWidth
                  %%
                  <<addSubterms(NumOfNew)>>
               else
                  %%
                  %%  actual width is bigger than initially allowed
                  %% (because manual expansions);
                  EndNum = StartNum - 1 + NumReuse
                  %%  Note that this covers both cases
                  %% -  no subterms should be created
                  %%      (from StartNum-1 to startNum);
                  %% -  'NumReuse' subterms should be re-created;
                  %%
               end
               %%
               <<createSubtermObjs(StartNum EndNum SubsList)>>
            else
               EndNum = TWidth
               %%
               NumOfNew = TWidth - StartNum + 1 - NumReuse
               case NumOfNew > 0 then <<addSubterms(NumOfNew)>>
               else true
               end
               %%
               <<createSubtermObjs(StartNum TWidth SubsList)>>
            end
            %%
         end
      end
      %%
   end
   %%
   %%
   %%  Well-formed lists;
   %%
   class WFListTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         name                   % print name;
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'WFListTermTermObject::initTerm is applied'#self.term}
\endif
         self.name = ''
         %% self.subterms = self.term   % clever??! :))
         %% ... and now 'self.term' is used instead of 'self.subterms';
         %%
         local SWidth TWidth in
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Length self.term}
            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>
               %%
               %% commas;
               %%
               <<createSubtermObjs(1 SWidth self.term)>>
            else
               <<subtermsStoreInit(TWidth False)>>
               %%
               <<createSubtermObjs(1 TWidth self.term)>>
            end
            %%
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.term
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.term
      end
      %%
   end
   %%
   %%  Tuples;
   %%
   class TupleTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         name                   % print name;
         subterms               % list of subterms;
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'TupleTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Store Subterms SWidth TWidth in
            Term = self.term
            Store = self.store
            %%
            self.name = <<genLitPrintName({Label Term} $)>>
            Subterms = {TupleToList Term}
            self.subterms = Subterms
            %%
            SWidth = {Store read(StoreWidth $)}
            TWidth = {Width Term}
            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>
               %%
               %% commas;
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
            %%
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.subterms
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.subterms
      end
      %%
   end
   %%
   %%
   %%  Lists;
   %%
   class ListTermTermObject
      %%
      %%  Actually, it could be implemented more efficiently -
      %% when the functionality of 'TupleSubtermsStore' is encoded
      %% directly in this class;
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         subterms               % list of subterms;
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ListTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Subterms  in
            Term = self.term
            %%
            Subterms = [Term.1 Term.2]
            self.subterms = Subterms
            %%
            %%  the width is always 2;
            <<subtermsStoreInit(2 False)>>
            %%
            <<createSubtermObjs(1 2 Subterms)>>
            %%
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.subterms
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.subterms
      end
      %%
   end
   %%
   %%
   %%  Hash tuples;
   %%
   class HashTupleTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         subterms               % list of subterms;
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'HashTupleTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Subterms SWidth TWidth in
            Term = self.term
            %%
            Subterms = {TupleToList Term}
            self.subterms = Subterms
            %%
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Width Term}
            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>
               %%
               %% commas;
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
            %%
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.subterms
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.subterms
      end
      %%
   end
   %%
   %%
   %%  Flat lists;
   %%
   class FListTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      %%
      %%
      attr
         subterms               % list of subterms;
         tailVar                % 'tail' variable, if any;
                                % it contains *always* it, even if it's currently
                                % not shown!
         tailVarNum             % number of 'tail' variable subterm, if any -
                                % in the case when it's currently shown;
      %%  Note that 'subterms' is an *attribute* here;
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'FListTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Store Subterms TailVar SWidth TWidth in
            Term = self.term
            Store = self.store
            %%
            %%  get subterms and a tail variable, if any;
            {SelSubTerms Term Store Subterms TailVar}
            subterms <- Subterms
            tailVar <- TailVar
            %%
            SWidth = {Store read(StoreWidth $)}
            TWidth = {Length Subterms}
            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>
               %%
               %% commas;
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
               %%
               tailVarNum <- ~1
            else
               <<subtermsStoreInit(TWidth False)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
               %%
               %% relational;
               case TailVar
               of !InitValue then
                  tailVarNum <- ~1
               [] _ then
                  tailVarNum <- TWidth
               end
            end
            %%
         end
      end
      %%
      %%  special: set the 'tailVarNum' attribute;
      %% ('reGetSubterms' should be already called;)
      meth initMoreSubterms(StartNum NumReuse SubsList ?EndNum)
         <<MetaTupleTermTermObject
         initMoreSubterms(StartNum NumReuse SubsList EndNum)>>
         %%
         <<setTailVarNum(EndNum)>>
      end

      %%
      %%  Sets 'tailVarNum' properly;
      meth setTailVarNum(OccNum)
         local TailVar in
            TailVar = @tailVar
            %%
            %% relational;
            case TailVar
            of !InitValue then
               tailVarNum <- ~1
            [] _ then
               local Obj in
                  Obj = <<getSubtermObj(OccNum $)>>
                  %%
                  %% relational;
                  case Obj.term
                  of !TailVar then
                     tailVarNum <- OccNum
                  [] _ then
                     tailVarNum <- ~1
                  end
               end
            end
         end
      end
      %%
      %%
      meth noTailVar
         tailVarNum <- ~1
         %%
\ifdef DEBUG_TT
         case @tailVar
         of !InitValue then true
         [] _ then
            {BrowserError ['FListTermTermObject::noTailVar: error!']}
         end
\endif
      end
      %%
      %%
      meth isWFList(?IsWF)
         local Depth in
            Depth = {self.store read(StoreNodeNumber $)}
            %%
            %% relational!
            IsWF = if {IsListDepth self.term Depth} then True
                   [] true then False
                   fi
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = @subterms
      end
      %%
      %%  updates 'subterms' and 'tailVar' in place;
      meth reGetSubterms(?Subterms)
         local TailVar in
            {SelSubTerms self.term self.store Subterms TailVar}
            %%
            subterms <- Subterms
            tailVar <- TailVar
            %%
         end
      end
      %%
   end
   %%
   %%
   %%  Generic compound (record-like) objects;
   %%
   class MetaRecordTermTermObject
      from MetaTupleTermTermObject
      %%
      feat
         name                   % print name;
         recArity               % list of features;
      %%  Note that 'recArity' is an incomplete list for open feature
      %% structures;
      %%
      %%
      attr
         subterms               % list of subterms;
         recFeatures            % tuple of the same arity which contains
                                % record's features;
      %%  'subterms' and 'recFeatures' is an attribute, since the number
      %% of features change over time for open feature structures;
      %%
   end
   %%
   %%  Records;
   %%
   class RecordTermTermObject
      from MetaRecordTermTermObject RecordSubtermsStore
      %%
      %%
      %%  We need 'setName' here and for 'AtomTermTermObject',
      %% since it is redefined for chunks (see further);
      %%
      meth setName
         self.name = <<genLitPrintName({Label self.term} $)>>
      end
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'RecordTermTermObject::initTerm is applied'#self.term}
\endif
         local
            AF AreSpecs Term Subterms Store RecArity RecFeatures SWidth TWidth
         in
            %%
            Store = self.store
            Term = self.term
            %%
            AF = case {Store read(StoreArityType $)}
                 of !AtomicArity then True
                 [] !TrueArity then False
                 else
                    {BrowserError
                     ['RecordTermTermObject::initTerm: invalid type of ArityType']}
                    False
                 end
            %%
            <<setName>>
            %%
            RecArity = case AF then {Arity Term}
                       else {RealArity Term}
                       end
            self.recArity = RecArity
            %%
            %%  'Subtree' is used because `.` behavior for cells;
            Subterms = {Map RecArity proc {$ F S} {Subtree Term F S} end}
            subterms <- Subterms
            %%
            TWidth = {Length RecArity}
            RecFeatures = {Tuple recFeatures TWidth}
            {FoldL RecArity fun {$ I E} RecFeatures.I = E (I + 1) end 1 _}
            %%
            recFeatures <- RecFeatures
            %%
            SWidth = {Store read(StoreWidth $)}
            %%
            AreSpecs = case AF then
                          case TWidth == {Width Term} then False
                             %% only atomic features;
                          else True
                          end
                       else False
                       end
            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True AreSpecs)>>
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False AreSpecs)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
            %%
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = @subterms
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = @subterms
      end
      %%
   end
   %%
   %%
   %%  Open feature structures;
   %%
   class ORecordTermTermObject
      from MetaRecordTermTermObject RecordSubtermsStore
      %%
      feat
         label                  % == {LabelC self.term $}
      %%
      attr
         name                   % for '_';
         tailVar                % tail variable in the list of features;
         CancelReq              %
         PrivateFeature         % == True if there is a private feature;
      %%
      %%
      meth setName
         name <- <<genLitPrintName({System.getPrintName self.label} $)>>
      end
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::initTerm is applied'#self.term}
\endif
         local
            AF RecArity Term OFSLab Subterms Store SWidth TWidth AreSpecs
            SelfClosed
         in
            %%
            Store = self.store
            Term = self.term
            %%
            AF = case {Store read(StoreArityType $)}
                 of !AtomicArity then True
                 [] !TrueArity then False
                 else
                    {BrowserError
                     ['RecordTermTermObject::initTerm: invalid type of ArityType']}
                    False
                 end
            %%
            %%  This *must* be a job, and *not* a thread!
            job
               OFSLab = {LabelC self.term}
            end
            self.label = OFSLab
            %%
            %%
            job
               SelfClosed = {Object.closed self}
            end

            %%
            case {IsVar OFSLab} then
               %% relational;
               thread
                  if {Det OFSLab True} then {self replaceLabel}
                  [] {Det SelfClosed True} then true
                     %% cancel watching;
                  fi
               end
            else true
            end
            %%
            <<setName>>
            self.name = @name   % just some value - it should not be used here;
            %%
            %%  incomplete list;
            %% {RecordC.monitorArity X K L}
            %%
            %% Constrains X to a record.  "Eagerly" constrains L to a list of all
            %% features of X, in some order. The order of the features will be "the
            %% order in which they arrive", as far as this is determined.  The list
            %% will contain an unbound tail as long as X is undetermined, and a nil
            %% tail when X is determined.
            %%
            %% The above definition is correct if K is undetermined.  Operationally,
            %% determining K removes the propagator and closes the list L.  The list
            %% then contains all features in X at the moment K is determined.  If
            %% called with K determined, the propagator returns a sorted list of the
            %% features existing in X at the moment of the call.  L is unaffected by
            %% any changes to X that occur after K becomes determined.
            %%
            %% Peter
            %%
            %%  This *must* be a job, and *not* a thread!
            job
               RecArity = {RecordC.monitorArity Term SelfClosed}
            end

            %%
            PrivateFeature <- False
            %%
            case AF then
               %%
               %% relational;
               thread
                  if {IsThereAName RecArity} = True then {self setHiddenPFs}
                  [] {IsValue SelfClosed True} then true
                  fi
               end
            else true
            end

            %%
            {Wait AF}

            %%
            case AF then
               %%  This *must* be a job, and *not* a thread!
               job
                  self.recArity = {AtomicFilter RecArity}
               end
               else self.recArity = RecArity
            end

            %%
            <<reGetSubterms(Subterms)>>

            %%
            TWidth = {Width @recFeatures}
            SWidth = {Store read(StoreWidth $)}

            %%
            AreSpecs = <<isProperOFS($)>>

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True AreSpecs)>>
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False AreSpecs)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
         end
      end
      %%
      %%
      meth isProperOFS(?Is)
         %% relational;
         Is = case @tailVar
              of !InitValue then False
              [] _ then True
              end
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::isProperOFS: '#Is}
\endif
      end
      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = @subterms
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         local Term TmpArity KnownArity TailVar RecFeatures in
            Term = self.term
            %%
            {GetWFListVar self.recArity TmpArity TailVar}
            %%  filter out already non-existing features -
            %%  cheers, Peter! ;-)
            {FoldL TmpArity
             fun {$ I E}
                if Vp in {SubtreeC Term E _} then
                   I = E|Vp Vp
                [] true then I
                fi
             end
%  The following doesn't work because 'TestC' fails if
% the record is determined (why ??!);
%            fun {$ I E}
%               case {TestC Term E} then
%                  Vp
%               in
%                  I = E|Vp Vp
%               else I
%               end
%            end
             KnownArity nil}
            %%
            %%  it could be 'InitValue' (if OFS has become a proper record
            %% already;)
            tailVar <- TailVar
            %%
            Subterms = {Map KnownArity proc {$ F S} {SubtreeC Term F S} end}
            subterms <- Subterms
            %%
            RecFeatures = {Tuple recFeatures {Length KnownArity}}
            {FoldL KnownArity fun {$ I E} RecFeatures.I = E (I + 1) end 1 _}
            recFeatures <- RecFeatures
            %%
         end
      end

      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::initTypeWatching: '#self.term}
\endif
         %%
         %%  Note that it covers also the case when 'tailVar' gets bound
         %% meanwhile;
         case <<isProperOFS($)>> then
            local Term Depth TailVar CancelVar in
               %%
               Term = self.term
               Depth = @depth
               TailVar = @tailVar
               CancelReq <- CancelVar
               %%
               %% Note that this conditional may not block the state;
               %% relational;
               thread
                  if {Det TailVar True} then
                     %%
                     {self extend}
                  [] {TestVarProc Term} then
                     %%
                     case {self.termsStore checkCorefs(self $)} then
                        %% gets bound somehow;
                        {self.parentObj renewNum(self Depth)}
                     else
                        %%  wait for a 'TailVar';
                        {self initTypeWatching}
                     end
                  [] {Det CancelVar True} then true
                  fi
               end
               %%
            end
         else true              % nothing to do - it's a proper record;
         end
      end

      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end
      %%
      %%
      meth setHiddenPFs
         Depth
      in
         PrivateFeature <- True
         Depth = @depth
         %%
         case <<isProperOFS($)>> then
            <<addQuestion>>
         else
            %%
            %%  I'm lazy - I tell you :))
            job
               {self.parentObj renewNum(self Depth)}
            end
         end
      end
      %%
   end
   %%
   %%
   %%
   %%  Generic chunks (not only, though) objects;
   %%
   class MetaChunkTermTermObject
      from AtomTermTermObject RecordTermTermObject
      %%
      feat
         isCompound             % 'True' if there are any subterms;
                                % (in another words, "{Width Term} \= 0");
      %%
      %%   Note that we have redefined 'Width' so that
      %%  {Width X} == {Length {RealArity X}}  !!!
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'MetaChunkTermTermObject::initTerm is applied'#self.term}
\endif
         case {Width self.term} == 0 then
            self.isCompound = False
            <<AtomTermTermObject initTerm>>
         else
            self.isCompound = True
            <<RecordTermTermObject initTerm>>
         end
      end
      %%
      %%
      meth getSubterms(?Subterms)
         case self.isCompound then
            <<RecordTermTermObject getSubterms(Subterms)>>
         else
            %% should produce an error message;
            <<AtomTermTermObject getSubterms(Subterms)>>
         end
      end
      %%
      %%
      meth reGetSubterms(?Subterms)
         case self.isCompound then
            <<RecordTermTermObject reGetSubterms(Subterms)>>
         else
            %% should produce an error message;
            <<AtomTermTermObject reGetSubterms(Subterms)>>
         end
      end
      %%
      %%
      meth areCommas(?Are)
         case self.isCompound then
            <<RecordTermTermObject areCommas(Are)>>
         else
            <<AtomTermTermObject areCommas(Are)>>
         end
      end
      %%
      %%
   end
   %%
   %%
   %%  Procedures;
   %%
   class ProcedureTermTermObject
      from MetaChunkTermTermObject
      %%
      %%
      meth setName
         self.name = {GenProcPrintName self.term self.store}
      end
      %%
   end
   %%
   %%
   %%  Objects;
   %%
   class ObjectTermTermObject
      from MetaChunkTermTermObject
      %%
      %%
      meth setName
         self.name = {GenObjPrintName self.term self.store}
      end
      %%
   end
   %%
   %%
   %%  Cells;
   %%
   class CellTermTermObject
      from MetaChunkTermTermObject
      %%
      %%
      meth setName
         self.name = {GenCellPrintName self.term self.store}
      end
      %%
   end
   %%
   %%
   %%  Classes;
   %%
   class ClassTermTermObject
      from MetaChunkTermTermObject
      %%
      %%
      meth setName
         self.name = {GenClassPrintName self.term self.store}
      end
      %%
   end
   %%
   %%
   %%
   %%  Special terms;
   %%
   %%  Variables;
   %%
   class VariableTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
      %%
      attr
         CancelReq              % watching is cancelled when it gets bound;
      %%
      %%
      %%
      meth getVarName(?Name)
         Name = {GenVarPrintName {System.getPrintName self.term}}
      end
      %%
      %%  Yields 'True' if it is still an (unconstrained!) variable;
      %%
      meth checkIsVar(?Is)
         local Term in
            Term = self.term
            %%
            %%  There could happen just everything: gets a value or
            %% some other (derived) type of variables;
            %%
            %% relational;
            Is = if {Det Term True} then False
                 [] {IsRecordCVar Term} then False
                 [] true then
                    %% relational;
                    if {IsFdVar Term} then False
                    [] {IsMetaVar Term} then False
                    else True
                    fi
                 fi
         end
      end
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'VariableTermTermObject::initTerm is applied'#self.term}
\endif
         local Name in
            %%
            Name = <<getVarName($)>>

            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>
         end
      end
      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'VariableTermTermObject::initTypeWatching: '#self.term}
\endif
         local CancelVar Depth NewName OldNameStr NewNameStr in
            %%
            Depth = @depth
            CancelReq <- CancelVar
            %%
            %% Note that this conditional may not block the state;
            thread
               %% relational;
               if {TestVarProc self.term} then
                  {self.parentObj renewNum(self Depth)}
               [] {Det CancelVar True} then true
               fi
            end
            %%
            %%  Check #1: is it still an (unconstrained) variable at all??
            case <<checkIsVar($)>> then
               %%
               %%  Check #2: the printname (for the case when one variable
               %% is bound to another one);
               NewName = <<getVarName($)>>
               OldNameStr = {VirtualString.toString self.name}
               NewNameStr = {VirtualString.toString NewName}
               %%
               case {DiffStrs OldNameStr NewNameStr} then
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else true
               end
               %%
            else
               %%
               job
                  {self.parentObj renewNum(self Depth)}
               end
            end
         end
      end
      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'VariableTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end
      %%
   end
   %%
   %%
   %%  Finite domain variables;
   %%
   class FDVariableTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
         card                   % actual domain size;
      %%
      attr
         CancelReq              % watching is cancelled when it gets bound;
      %%
      %%
      %%
      meth getVarName(?Name)
         Name = {GenVarPrintName {System.getPrintName self.term}}
      end
      %%
      %%  Yields 'True' if it is still a FD variable;
      %%
      meth checkIsVar(?Is)
         %%
         %%  There could happen only one thing: it can get a value;
         %%
         Is = {IsVar self.term}
      end
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'FDVariableTermTermObject::initTerm is applied'#self.term}
\endif
         local Term ThPrio SubIntsL SubInts Le DomComp Name in
            Term = self.term
            %%
            ThPrio = {Thread.getPriority}
            %%
            %%  critical section!
            {Thread.setHighIntPri}
            %%
            self.card = {FD.reflect.size Term}
            %%
            DomComp = {FD.reflect.dom Term}
            %%
            {Thread.setPriority ThPrio}
            %%  end of critical section;
            %%
            {List.mapInd DomComp
             %% relational;
             fun {$ Num Interval}
                local Tmp in
                   Tmp = if L H in Interval = L#H then L#"#"#H
                         else Interval
                         fi
                   %%
                   case Num == 1 then Tmp
                   else " "#Tmp
                   end
                end
             end
             SubIntsL}
            %%
            Le = {Length SubIntsL}
            SubInts = {Tuple '#' Le}
            {Loop.for 1 Le 1 proc {$ I} SubInts.I = {Nth SubIntsL I} end}
            %%
            %%  first subterm in hash-tuple must be a variable name!
            %% (see beneath in :initTypeWatching;)
            Name = <<getVarName($)>>#DLCBraceS#SubInts#DRCBraceS

            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>
         end
      end
      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'FDVariableTermTermObject::initTypeWatching: '#self.term}
\endif
         local CancelVar Depth NewName OldNameStr NewNameStr in
            %%
            Depth = @depth
            CancelReq <- CancelVar
            %%
            %% Note that this conditional may not block the state;
            thread
               %% relational;
               if {TestFDVarProc self.term self.card} then
                  {self.parentObj renewNum(self Depth)}
               [] {Det CancelVar True} then true
               fi
            end
            %%
            %%  Check #1: is it still a FD variable at all??
            case <<checkIsVar($)>> then
               %%
               %%  Check #2: the printname (for the case when one variable
               %% is bound to another one);
               NewName = <<getVarName($)>>
               OldNameStr = {VirtualString.toString self.name.1}
               NewNameStr = {VirtualString.toString NewName}
               %%
               case {DiffStrs OldNameStr NewNameStr} then
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else true
               end
               %%
            else
               %%
               job
                  {self.parentObj renewNum(self Depth)}
               end
            end
         end
      end
      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'FDVariableTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end
      %%
   end
   %%
   %%
   %%  Meta variables;
   %%
   class MetaVariableTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
         strength               % actual strength of constraint at this var;
      %%
      attr
         CancelReq              % watching is cancelled when it gets bound;
      %%
      %%
      %%
      meth getVarName(?Name)
         Name = {GenVarPrintName {System.getPrintName self.term}}
      end
      %%
      %%  Yields 'True' if it is still a metavariable;
      %%
      meth checkIsVar(?Is)
         %%
         %%  There could happen only one thing: it can get a value;
         %%
         IsVar = {IsVar self.term}
      end
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'MetaVariableTermTermObject::initTerm is applied'#self.term}
\endif
         local Term ThPrio Data MetaName Name in
            Term = self.term
            %%
            ThPrio = {Thread.getPriority}
            %%
            %%  critical section!
            {Thread.setHighIntPri}
            %%
            self.strength = {MetaGetStrength Term}
            %%
            Data = {MetaGetDataAsAtom Term}
            %%
            MetaName = {MetaGetNameAsAtom Term}
            %%
            {Thread.setPriority ThPrio}
            %%  end of critical section;
            %%
            %%  first subterm in hash-tuple must be a variable name!
            %% (see beneath in :initTypeWatching;)
            Name = <<getVarName($)>>#'<'#MetaName#':'#Data#'>'
\ifdef DEBUG_METAVAR
            {Show ['Data'#Data 'MetaName'#MetaName
                   'self.strength'#self.strength 'Name'#Name]}
\endif

            %%
            {Wait Name}

            %%
            self.name = Name
            <<nil>>

            %%
\ifdef DEBUG_METAVAR
            {Show 'self.name'#self.name}
\endif
         end
      end
      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'MetaVariableTermTermObject::initTypeWatching: '#self.term}
\endif
         local CancelVar Depth NewName OldNameStr NewNameStr in
            %%
            Depth = @depth
            CancelReq <- CancelVar
            %%
            %% Note that this conditional may not block the state;
            thread
               %% relational;
               if {TestMetaVarProc self.term self.strength} then
                  {self.parentObj renewNum(self Depth)}
               [] {Det CancelVar True} then true
               fi
            end
            %%
            %%  Check #1: is it still a FD variable at all??
            case <<checkIsVar($)>> then
               %%
               %%  Check #2: the printname (for the case when one variable
               %% is bound to another one);
               NewName = <<getVarName($)>>
               OldNameStr = {VirtualString.toString self.name.1}
               NewNameStr = {VirtualString.toString NewName}
               %%
               case {DiffStrs OldNameStr NewNameStr} then
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else true
               end
               %%
            else
               %%
               job
                  {self.parentObj renewNum(self Depth)}
               end
            end
         end
      end
      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'MetaVariableTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end
      %%
   end
   %%
   %%
   %%  References;
   %%
   class ReferenceTermTermObject
      from MetaTermTermObject
      %%
      %%  Note that 'name' is an *attribute* here!
      attr
         name                   % print name;
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ReferenceTermTermObject::initTerm is applied'#self.term}
\endif
         name <- '?'
      end
      %%
      %%
      meth setRefVar(Master Name)
\ifdef DEBUG_TT
         {Show 'ReferenceTermTermObject::setRefVar is applied'#self.term}
\endif
         master <- Master
         name <- Name
         size <- {VSLength Name}
         %%
         job
            {self.parentObj redrawNum(self)}
         end
      end
      %%
      %%
   end
   %%
   %%
   %%  Shrunken (sub)terms;
   %%
   class ShrunkenTermTermObject
      from MetaTermTermObject
      %%
      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ShrunkenTermTermObject::initTerm is applied'#self.term}
\endif
         true
      end
      %%
   end
   %%
   %%
   %%
   %%  Unknown terms;
   %%
   class UnknownTermTermObject
      from MetaTermTermObject
      %%
      feat
         name: '<UNKNOWN TERM>'         % print name;
      %%
      %%
      %%  We need 'setName' here and for 'RecordTermTermObject', since
      %% it's redefined for chunk objects;
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'UnknownTermTermObject::initTerm is applied'#self.term}
\endif
         true
      end
   end
   %%
   %%
%%%
%%%
%%%  Various local auxiliary procedures;
%%%
   %%
   %%
   local
      %%
      %%
      [ZeroChar] = "0"
      %%
      fun {OctString I}
         [(I div 64) mod 8 + ZeroChar
          (I div 8)  mod 8 + ZeroChar
          I mod 8 + ZeroChar]
      end
   in
      %%
      local
         SetTab       = {Tuple tab 255}
         ScanTab      = {Tuple tab 255}
         SubstTab     = {Tuple tab 255}
         %%
         {Tuple.forAllInd SetTab
          fun {$ I}
             case {Char.isAlNum I} then legal
             elsecase [I]=="_"      then legal
             elsecase {Char.isCntrl I} then
                subst(case [I]
                      of "\a" then "\\a"
                      [] "\b" then "\\b"
                      [] "\f" then "\\f"
                      [] "\n" then "\\n"
                      [] "\r" then "\\r"
                      [] "\t" then "\\t"
                      [] "\v" then "\\v"
                      else {Append "\\" {OctString I}}
                      end)
             elsecase I =< 255 andthen 127 =< I then
                subst({Append "\\" {OctString I}})
             elsecase [I]=="'" then
                subst("\\\'")
             elsecase [I]=="\\" then
                subst("\\\\")
             else illegal
             end
          end}
         %%
         ScanTab  = {Tuple.map SetTab fun {$ T} {Label T} end}
         SubstTab = {Tuple.map SetTab
                     fun {$ T}
                        case {IsAtom T} then nil else T.1 end
                     end}
         %%
         %% Check whether atom needs to be quoted and expand quotes in string
         fun {Check Is NeedsQuoteYet ?NeedsQuote}
            case Is of nil then
               NeedsQuote = NeedsQuoteYet
               nil
            [] I|Ir then
               case ScanTab.I
               of legal   then I|{Check Ir NeedsQuoteYet ?NeedsQuote}
               [] illegal then I|{Check Ir True ?NeedsQuote}
               [] subst   then
                  {Append SubstTab.I {Check Ir True ?NeedsQuote}}
               end
            end
         end
         %%
      in
         %%
         fun {GenAtomPrintName Atom}
            case Atom=='' then "\'\'"
            else
               Is={AtomToString Atom}
               NeedsQuote
               Js={Check Is {Bool.'not' {Char.isLower Is.1}} ?NeedsQuote}
            in
               case NeedsQuote then "'"#Js#"'" else Js end
            end
         end
         %%
         fun {GenVarPrintName Atom}
            case Atom
            of '\`\`' then "\`\`"
            [] nil then '_'     % ad'hoc;
            else
               Is = {AtomToString Atom}
            in
               {Check Is {Bool.'not' {Char.isUpper Is.1}} _}
            end
         end
      end
      %%
      local
         SetTab       = {Tuple tab 256}
         SubstTab     = {Tuple tab 256}
         ScanTab      = {Tuple tab 256}
         %%
         {Tuple.forAllInd SetTab
          fun {$ J} I=J-1 in
             case {Char.isCntrl I} then
                subst(case [I]
                      of "\a" then "\\a"
                      [] "\b" then "\\b"
                      [] "\f" then "\\f"
                      [] "\n" then "\\n"
                      [] "\r" then "\\r"
                      [] "\t" then "\\t"
                      [] "\v" then "\\v"
                      else {Append "\\" {OctString I}}
                      end)
             elsecase I =< 255 andthen 127 =< I then
                subst({Append "\\" {OctString I}})
             else
                case [I]=="\"" then subst("\\\"")
                elsecase [I]=="\\" then subst("\\\\")
                else legal
                end
             end
          end}
         %%
         ScanTab  = {Tuple.map SetTab fun {$ T} {Label T} end}
         SubstTab = {Tuple.map SetTab
                     fun {$ T}
                        case {IsAtom T} then "" else T.1 end
                     end}
         %%
         fun {QuoteString Is}
            case Is of nil then nil
            [] I|Ir then J=I+1 in
               case ScanTab.J
               of legal   then I|{QuoteString Ir}
               [] subst   then {Append SubstTab.J {QuoteString Ir}}
               end
            end
         end
         %%
         proc {HashVS I V1 V2}
            V2.I={GenVS V1.I}
            case I>1 then {HashVS I-1 V1 V2} else true end
         end
         %%
         fun {GenVS V}
            case {Value.type V}
            of int then V
            [] float then V
            [] atom then
               case V
               of nil then ''
               [] '#' then ''
               [] '' then ''
               else {QuoteString {AtomToString V}}
               end
            [] tuple then
               case {Label V}
               of '|' then {QuoteString V}
               [] '#' then W={Width V} V2={Tuple '#' W} in
                  {HashVS W V V2} V2
               end
            end
         end
      in
         %%
         %%
         fun {GenVSPrintName V}
            '"'#{GenVS V}#'"'
         end
      end
   end
   %%
   %%
   %%  Extract a 'meaningful' part of a temporary name;
   local ParseFun in
      fun {ParseFun I CI E}
         case E == CNameDelimiter then I else CI end
      end
      %%
      %%
      fun {StripName IStr}
         local Pos in
            Pos = {List.foldLInd IStr ParseFun 0}
            %%
            case Pos == 0 then IStr else {Head IStr Pos-1} end
         end
      end
   end
   %%
   %%
   fun {StripBQuotes IStr}
      case IStr == nil then nil
      else
         case IStr.1 == BQuote then {StripBQuotes IStr.2}
         else IStr.1|{StripBQuotes IStr.2}
         end
      end
   end
   %%
   %%
   %%  Generate a printname for a name;
   proc {GenNamePrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.getPrintName Term}
         %%
         case AreSmallNames then
            case PN == '' then Name = "<N>"
            else
               local SPNS SSPNS in
                  SPNS = {StripName {Atom.toString PN}}
                  %%
                  case SPNS.1 == BQuote then
                     SSPNS = {StripName {StripBQuotes SPNS}}
                     %%
                     case SSPNS == nil then Name = "<N>"
                     else Name = '#'("<N: `" SSPNS "`>")
                     end
                  else Name = '#'("<N: " SPNS ">")
                  end
               end
            end
         else
            %%
            case PN == '' then
               Name = '#'("<Name @ " {System.getValue Term addr} ">")
            else
               Name = '#'("<Name: " PN " @ " {System.getValue Term addr} ">")
            end
         end
      end
   end
   %%
   %%
   %%  Generate an object's print name;
   proc {GenObjPrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {Class.printName {Class Term}}
         %%
         case AreSmallNames then
            case PN == '_' then Name = "<O>"
            else
               local PNS SN in
                  PNS = {Atom.toString PN}
                  %%
                  case PNS.1 == BQuote then
                     SN = {StripName {StripBQuotes PNS}}
                     %%
                     case SN == nil then Name = "<O>"
                     else Name = '#'("<O: `" SN "`>")
                     end
                  else Name = '#'("<O: " PN ">")
                  end
               end
            end
         else
            case PN == '_' then
               Name = '#'("<Object @ " {System.getValue Term addr} ">")
            else
               Name = '#'("<Object: " PN " @ " {System.getValue Term addr} ">")
            end
         end
      end
   end
   %%
   %%
   %%  Generate an class's print name;
   proc {GenClassPrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {Class.printName Term}
         %%
         case AreSmallNames then
            case PN == '_' then Name = "<C>"
            else
               local PNS SN in
                  PNS = {Atom.toString PN}
                  %%
                  case PNS.1 == BQuote then
                     SN = {StripName {StripBQuotes PNS}}
                     %%
                     case SN == nil then Name = "<C>"
                     else Name = '#'("<C: `" SN "`>")
                     end
                  else Name = '#'("<C: " PN ">")
                  end
               end
            end
         else
            case PN == '_' then
               Name = '#'("<Class @ " {System.getValue Term addr} ">")
            else
               Name = '#'("<Class: " PN " @ " {System.getValue Term addr} ">")
            end
         end
      end
   end
   %%
   %%
   %%  Generate a procedure's print name;
   proc {GenProcPrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.getPrintName Term}
         %%
         case AreSmallNames then
            case PN == '_' then Name = '#'("<P/" {System.getValue Term arity} ">")
            else
               local PNS SN in
                  PNS = {Atom.toString PN}
                  %%
                  case PNS.1 == BQuote then
                     SN = {StripName {StripBQuotes PNS}}
                     %%
                     case SN == nil then
                        Name = '#'("<P/" {System.getValue Term arity} ">")
                     else
                        Name = '#'("<P/" {System.getValue Term arity} " `" SN "`>")
                     end
                  else
                     Name = '#'("<P/" {System.getValue Term arity} " " PN ">")
                  end
               end
            end
         else
            Name = '#'("<Procedure: " PN "/" {System.getValue Term arity} " @ "
                       {System.getValue Term addr} ">")
         end
      end
   end
   %%
   %%
   %%  Generate a cell's print name;
   proc {GenCellPrintName Term Store ?Name}
      local AreSmallNames CN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         CN = {System.getPrintName Term}
         %%
         case AreSmallNames then
            case CN == '_' then Name = "<Cell>"
            else
               local PNS SN in
                  PNS = {Atom.toString CN}
                  %%
                  case PNS.1 == BQuote then
                     SN = {StripName {StripBQuotes PNS}}
                     %%
                     case SN == nil then Name = "<C>"
                     else Name = '#'("<Cell: `" SN "`>")
                     end
                  else Name = '#'("<Cell: " CN ">")
                  end
               end
            end
         else
            Name = '#'("<Cell: " CN " @ " {System.getValue Term cellName} ">")
         end
      end
   end
   %%
   %%
   %%  'Watch' procedures;
   %%
   proc {TestVarProc Var}
      {GetsBound Var}
   end
   %%
   %%
   proc {TestFDVarProc FDVar Card}
      if {WatchDomain FDVar Card} then true
      [] {GetsBound FDVar} then true
         %% let us watch for both events;
      fi
   end
   %%
   %%
   %%
   proc {TestMetaVarProc MetaVar Strength}
      if {WatchMetaVar MetaVar Strength} then true
      [] {GetsBound MetaVar} then true
         %% let us watch for both events;
      fi
   end
   %%

   %%
   %%
   fun {LArity R AF}
      %%
      case AF then {RealArity R}
      else {Arity R}
      end
   end
   %%
   %%
   %%  Rudimentary, but still useful here...
   %%
   fun {TupleToList Tuple}
      local WidthOf ListOf in
         WidthOf = {Width Tuple}
         ListOf = {List WidthOf}

         %
         {FoldL ListOf fun {$ Num E} E = Tuple.Num Num + 1 end 1 _}
         ListOf
      end
   end
   %%
   %%
   %%  GetListType;
   %%  'Store' is the parameters store, 'AreBraces' says whether this list
   %% should be exposed in braces or not, 'Attr' gets the 'InitValue' or the
   %% tail variable if the type is T_FList or T_BFList;
   fun {GetListType List Store}
      local Depth in
         Depth = {Store read(StoreNodeNumber $)}
         %%
         if {IsListDepth List Depth} then T_WFList
         [] true then           % non-monotonic;
            local AreFLists in
               AreFLists = {Store read(StoreFlatLists $)}
               %%
               case AreFLists then T_FList
               else T_List
               end
            end
         end
      end
   end
   %%

   %%
   %%  Note: that's not a function!
   proc {IsListDepth L D}
      case D > 0 then
         %% 'List.is' exactly;
         %%
         case L
         of _|Xr then {IsListDepth Xr (D-1)}
         else L = nil
         end
      else L = nil
      end
   end
   %%
   %%
   %%  Flat representation of incomplete lists;
   %%  Extract subterms and a trailing variable from given list;
   %%
   local
      DoInfList IsCyclicListDepth DoCyclicList
      GetBaseList GetListAndVar
   in
      %%
      %%  A 'new edition' of the 'IsCyclicList';
      %%  We consider simply the limited number of list constructors;
      %%
      proc {DoInfList Xs Ys Depth}
         case Depth > 0 then
            %% relational;
            if Xr Yr in Xs=_|Xr Ys=_|_|Yr then
               %% relational;
               case {EQ Xr Yr} then true
               else
                  if {DoInfList Xr Yr (Depth-1)} then true
                  else false
                  fi
               end
            else false
            fi
         else false
         end
      end
      %%
      proc {IsCyclicListDepth Xs Depth}
         case Xs of X|Xr then
            {DoInfList Xs Xr (Depth + Depth + 1)}
         end
      end
      %%
      proc {SelSubTerms List Store ?Subterms ?Var}
         local Depth Corefs Cycles in
            {Store [read(StoreNodeNumber Depth)
                    read(StoreCheckStyle Corefs)
                    read(StoreOnlyCycles Cycles)]}
            %%
            case Corefs orelse Cycles then
               %% relational;
               if {IsCyclicListDepth List Depth} then
                  {DoCyclicList List nil ?Subterms}
                  Var = InitValue
               [] true then     % not yet instantiated;
                  {GetListAndVar List Depth Subterms Var}
               fi
            else {GetListAndVar List Depth Subterms Var}
            end
         end
      end
      %%
      proc {DoCyclicList List Stack ?Subterms}
         %% relational;
         if LS in {GetBaseList List Stack Stack LS}
         then Subterms = LS
         else {DoCyclicList List.2 List|Stack ?Subterms}
         fi
      end
      %%
      proc {GetListAndVar List Depth ?Subterms ?Var}
         case Depth > 0 then
            %% relational;
            if H R NS in List = H|R then
               Subterms = H|NS
               {GetListAndVar R (Depth - 1) NS Var}
            [] {Det List True} then
               Subterms = [List]
               Var = InitValue
            [] true then
               Subterms = [List]
               Var = List
            fi
         else
            Subterms = [List]
            Var = InitValue
         end
      end
      %%
      %% fails if no recursion was detected;
      proc {GetBaseList List Stack SavedStack ?BaseList}
         case Stack == nil then false
         else
            %% relational;
            case {EQ List {Subtree Stack 1}} then
               case Stack.2 == nil then
                  %% i.e. the cycle begins from the first list constructor;
                  BaseList = {Append {Map {Reverse SavedStack}
                                      fun {$ E} E.1 end} [List]}
               else
                  BaseList = {Append {Map {Reverse Stack.2}
                                      fun {$ E} E.1 end} [List]}
               end
            else
               {GetBaseList List Stack.2 SavedStack ?BaseList}
            end
         end
      end
   end
   %%
   %%  ... used for open feature constraints browsing;
   proc {GetWFListVar LIn ?WFL ?Var}
      %%
      %% relational;
      case LIn
      of E|R then
         WFL = E|{GetWFListVar R $ Var}
      [] nil then
         WFL = nil
         Var = InitValue
      [] TailVar then
         WFL = nil
         Var = TailVar
      end
   end
   %%
   %%  Filter for 'RecordC.monitorArity';
   fun {AtomicFilter In}
      case In
      of E|R then
         case {IsAtom E} then E|{AtomicFilter R}
         else {AtomicFilter R}
         end
      else nil
      end
   end
   %%
   %%  Yields 'True' if there is a name;
   fun {IsThereAName In}
      case In
      of E|R then
         case {IsName E} then True
         else {IsThereAName R}
         end
      else False
      end
   end
   %%
end
