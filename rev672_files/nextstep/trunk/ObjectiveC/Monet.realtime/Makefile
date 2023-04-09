CLASSES = BooleanExpression.m BooleanTerminal.m CategoryList.m\
	CategoryNode.m Event.m EventList.m FormulaExpression.m\
	FormulaTerminal.m NamedList.m Parameter.m ParameterList.m\
	Phone.m PhoneList.m Point.m ProtoEquation.m ProtoTemplate.m\
	PrototypeManager.m RealTimeController.m Rule.m RuleList.m\
	Slope.m SlopeRatio.m Symbol.m SymbolList.m\
	Target.m TargetList.m stringParser.m IntonationPoint.m


OFILES  = BooleanExpression.o BooleanTerminal.o CategoryList.o\
	CategoryNode.o Event.o EventList.o FormulaExpression.o\
	FormulaTerminal.o NamedList.o Parameter.o ParameterList.o\
	Phone.o PhoneList.o Point.o ProtoEquation.o ProtoTemplate.o\
	PrototypeManager.o RealTimeController.o Rule.o RuleList.o\
	Slope.o SlopeRatio.o Symbol.o SymbolList.o Target.o\
	TargetList.o stringParser.o IntonationPoint.o driftGenerator.o

HFILES  = BooleanExpression.h BooleanTerminal.h CategoryList.h\
	CategoryNode.h Event.h EventList.h FormulaExpression.h\
	FormulaTerminal.h NamedList.h Parameter.h ParameterList.h\
	Phone.h PhoneList.h Point.h ProtoEquation.h ProtoTemplate.h\
	PrototypeManager.h RealTimeController.h Rule.h RuleList.h\
	Slope.h SlopeRatio.h Symbol.h SymbolList.h\
	Target.h TargetList.h 

LIBS = -lDriver -ldsp -lNeXT_s
CFLAGS = -g -arch m68k -arch i386
#CFLAGS = -g -arch m68k

test: main.c monet.a
	cc -ObjC  -arch m68k main.c monet.a $(LIBS) tube_module/obj/synthesizer_module.a

monet.a: $(OFILES)
	ld -r -arch m68k $(OFILES) -o monet.a.m68k
	ld -r -arch i386 $(OFILES) -o monet.a.i386
	lipo -output monet.a -create monet.a.m68k monet.a.i386
	/bin/rm monet.a.m68k
	/bin/rm monet.a.i386

.m.o: ; cc -c -O -ObjC $(CFLAGS) -o $@ $*.m

.c.o: ; cc -c -O $(CFLAGS) -o $@ $*.c
