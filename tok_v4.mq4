//+------------------------------------------------------------------+
//|                                                       tok_v4.mq4 |
//|                                Copyright 2021, Octavio Rodriguez |
//|                                                   toktrading.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Octavio Rodriguez"
#property link      "toktrading.net"
#property version   "4.00"
#property strict

//+------------------------------------------------------------------+
//|Inputs   TDI                                                      |
//+------------------------------------------------------------------+
input int    VELASINICIO =  215; //Velas de Inicio
input double PIPSIMPULSOMINIMO= 25.0; //Impulso Minimo
input int    NUMREDIBUJO = 35;

double minimoValue1,minimoValue2,minimoValue3;
int    minimoIndex1,minimoIndex2,minimoIndex3;

double maximoValue1,maximoValue2,maximoValue3;
int    maximoIndex1,maximoIndex2,maximoIndex3;

string linea1,linea2,linea3,linea4,linea5,linea6,linea7,linea8,linea9,linea10,linea11,linea12;

int barrasActuales = 0;

//+------------------------------------------------------------------+
//|Inputs toktrading                                                 |
//+------------------------------------------------------------------+
//caduca
   int limityear  = 2021;
   int limitmonth = 5;
   int limitday   = 16;
   
//cuentas aprobadas
   int cuenta1 = 4830;
   int cuenta2 = 0934;
   int cuenta3 = 5025;
   int cuenta4 = 8101;

//inputs
  ENUM_TIMEFRAMES timeframe=0;
  double tpPorciento =0.55;
  
  //cruces de la trampa
  input double cruceMinimo = 100; //Cruce Minimo %
  input double cruceMaximo = 160; //Cruce Maximo %
  double pilladaMin = (cruceMinimo-100)/100;   
  double pilladaMax = (cruceMaximo-100)/100;
  
  input double pipsBreakEven = 1.0;
  input double TPminimo = 10.0;
  input int velasMaxTrampa = 100;
  bool MoverDespuesVela = false;
  input bool TPcuerpo =  true;
  input bool entradaMartillo = false;
  int plusGestionCL = 0;
  int plusGestionBE=5;
  
  
  
  //bool Dibujar_Fibo =  false;
  bool Reentrada = false;
  bool Pending20 = false;
  double porcentajePending =0.20;
  double porcentajePendingAlocation = .20;

  //inputs de BE positivo
  bool BePositivo = false;
  double  BePositivoPorciento = 50;
  enum TipoDeBE  {PuntoGestion,BE };
  TipoDeBE  tipoBePositivo = 0;

  //inputs de riesgo
  enum TipoDeRiesgo{ PORCENTAJE, MONEDA, LOTAJE };
  input TipoDeRiesgo RiesgoTipo= 0; 
  input double CantidadRiesgo =2;

  // inputs de la tendencia
  bool tendeciaAutomatica = false;
  int pivotes = 50;

  double entradaPorcentajeMaximo = .99;
  

  int cantVelasEspera=2;

  string name ="FIB1";
  double delta,pilladaMinValor,pilladaMaxValor,gestionBE,SL,nivelTrampa,TP;
  int inicioTrampa,finTrampa;

  int limit;



  bool OPBOTON = false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {                                                      
//---
   //crear botones
   crearBotones(0,"Button1",0,1,20,75,18,2,"BUY");
   crearBotones(0,"Button2",0,79,20,75,18,2,"SELL");
   crearBotones(0,"Button3",0,1,44,153,23,2,"FIBX");
   crearBotones(0,"Button4",0,1,66,153,23,2,"FIB1");
   
   
   
   
   ObjectsDeleteAll(0,OBJ_TREND);
   linea1 = linea2 = linea3 =linea4 = linea5 = linea6 = "none";
   linea1 = velaInicial(VELASINICIO); 
   linea2 = velaInicial2(VELASINICIO);
   cicloInicial();
   barrasActuales = Bars;
   
   
   //revision de tiempo
   if(!timecheck()){
   Alert("Se termino el tiempo de este indicador");
   Print("ESe termino el tiempo de este indicador");
   ObjectsDeleteAll();
   return(INIT_FAILED);}
   
   if(logdhay())return(INIT_SUCCEEDED);
   if(IsTesting())return(INIT_SUCCEEDED);
   
   if(IsDemo()){
      return(INIT_SUCCEEDED);}
   else{
      Alert("Esta version solo funciona en cuentas demo");
      Print("Esta version solo funciona en cuentas demo");
      ObjectsDeleteAll();
      return(INIT_FAILED);
   }
   
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   //ObjectsDeleteAll();
   ObjectDelete(0,"Button1");
   ObjectDelete(0,"Button2");
   ObjectDelete(0,"Button3");
   ObjectDelete(0,"Button4");
   ObjectDelete(0,"Button5");
   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
   if(sparam == "Button1")  //se activa funcion cuando se detecta un toque del boton
     {
      ObjectSetInteger(NULL,"Button1",OBJPROP_STATE,false);
      Print("Compra manual por boton");
      OPBOTON = true;
      //se manda la orden
      getlevels("FIBX");
      if(nivelTrampa < TP)
         orderSend(1);
      OPBOTON = false;
      ObjectDelete(0,"FIBX");
     }
     
   if(sparam == "Button2")
     {
      ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
      Print("Venta manual por boton");
      OPBOTON = true;
      //se manda la orden
      getlevels("FIBX");
      if(nivelTrampa > TP)
         orderSend(-1);
      OPBOTON = false;
      ObjectDelete(0,"FIBX");
     }
     
   if(sparam == "Button3")
     {
      ObjectDelete(0,"FIBX");
      ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
      dibujarFibo("FIBX",clrRed);
     }
    if(sparam == "Button4")
     {
      ObjectDelete(0,"FIB1");
      ObjectSetInteger(NULL,"Button4",OBJPROP_STATE,false);
      dibujarFibo("FIB1",clrBlack);
     }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      //botones para el tester
      if(IsTesting())    botenesdeltester();
      
      
      
      if(Bars > barrasActuales){      
         int ultimoPunto;
         barrasActuales = Bars;
         GestionarEntradas();
   
         do{
         ultimoPunto = dibujarSecuencia();
         }
         while(ultimoPunto>0 && !IsStopped());
         lineasFib();
         
      for(int i=1; i<=20; i++)
        {

         // se revisa que solo si no hay operaciones abiertas se pueda abrir otra
         if(TotalOrderCount()>0)
            return;
         //toma de valores del fibo

         name = getName(i);
         if(name == "error")
            continue;
         getlevels(name);


         purchaseCheck();//algoritomo para revisar la compra
        }        
         
      
      }
   
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Algoritmo para crear las lineas iniciales                        |
//+------------------------------------------------------------------+
string velaInicial (int InicioIndex){
   //vamos a encontrar la primera linea que se formara con la primera vela para sacar maximos y minimo
   //ademas segun la orientacion de la vela diremos si es una tendencia bajista o alcista
   
   double velaOpen,velaClose;
   
   velaOpen =   iOpen (Symbol(),Period(),InicioIndex);
   velaClose =  iClose(Symbol(),Period(),InicioIndex);
   
   //tendencia alcista
   if(velaClose >= velaOpen){   
      return  drawLine(InicioIndex,InicioIndex,1);     
   }
   //tendencia bajista
   if(velaClose<velaOpen){
      return  drawLine(InicioIndex,InicioIndex,-1); 
   }
   
   return "error";
   
}

string velaInicial2 (int InicioIndex){
   //vamos a encontrar la primera linea que se formara con la primera vela para sacar maximos y minimo
   //ademas segun la orientacion de la vela diremos si es una tendencia bajista o alcista
   
   double velaOpen,velaClose;
   
   velaOpen =   iOpen (Symbol(),Period(),InicioIndex);
   velaClose =  iClose(Symbol(),Period(),InicioIndex);
   
   //tendencia alcista
   if(velaClose <= velaOpen){   
      return  drawLine(InicioIndex,InicioIndex,1);     
   }
   //tendencia bajista
   if(velaClose>velaOpen){
      return  drawLine(InicioIndex,InicioIndex,-1); 
   }
   
   return "error";
   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cicloInicial(){
   int ultimoPunto;
   
   do{
   ultimoPunto = dibujarSecuencia();
   }
   while(ultimoPunto>0 && !IsStopped());
   lineasFib();
   
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int dibujarSecuencia(){  
   int status, nI,piv;
   
   nivelesLinea(linea1,1);
   nivelesLinea(linea2,2);
   int direccion = dirLinea(linea1);
   
   
   //secuencia para deternimar que tipo de vela es la siguiente
   //1 rompre el maximo || -1 rompe el minimo || 3 rompe ambos || 4 no rompe

   nI = nextIndex(maximoIndex1,minimoIndex1);
   
   
   
   //cuando la linea anterior es una linea alcista = 1 en direccion
   if(direccion == 1){
      //for para encontrar la siguiente secuencia que mueva el precio
      for(int i = (nI - 1);i>0;i--){
      
         //protocolo para redibujar la linea depues del numero correcto de velas sin nuevo nivel
         if(nI - i > NUMREDIBUJO){
            redibujar(nI);
            return NUMREDIBUJO -1;
         }
         status = nuevaVelaActualizacion(maximoValue1,minimoValue1,i);
         
         /*
         if( i == 128){
            Comment   ("Hola");
         }
         */
         
         //se pasa a la siguiente iteracion 
         if(status == 0)continue;
         
         //cuando rompe maximo
         if(status == 1){
            
            //determinar si existe pivote     
            piv = pivoteMenorMayor(nI,i,-1);
            
            //se busca un pivote entre el maximo y el maximo anterior
            //cuando no se encuentra pivote se crea esta secuencia
            if(piv ==-1){
               nivelesLinea(linea1,1);
               ObjectDelete(0,linea1);                 
               linea1 = drawLine(minimoIndex1,i,1);
               nivelesLinea(linea1,1);
               if(pivoteDespuesRompimiento(1,i))return i;
               return i;                
            }
            if(piv == nI && piv == minimoIndex1 && i == (piv -1)){
               nivelesLinea(linea1,1);
               ObjectDelete(0,linea1);                 
               linea1 = drawLine(minimoIndex1,i,1);
               nivelesLinea(linea1,1);
               if(pivoteDespuesRompimiento(1,i))return i;
               return i;                
            }
            else{          
                  //revisamos si tiene la distancia correcta
                  if(distancePivot(piv,i,1)>=(PIPSIMPULSOMINIMO*10)){ 
                     //protocolo para ver si no existe nivel intermedio
                     if(pivoteDespuesRompimiento(1,i))return i;
                                     
                     alineacionBurbuja(drawLine(nI,piv,-1));
                     alineacionBurbuja(drawLine(piv,i,1));
                     return i;
                  }
                  else{//cuando no tiene la distancia
                     //secuencia para redibujar la linea1
                     nivelesLinea(linea1,1);
                     ObjectDelete(0,linea1);                 
                     linea1 = drawLine(minimoIndex1,i,1);
                     //pero se busca alomejor en un nivel intermedio si existe esa distancia
                     nivelesLinea(linea1,1);
                     if(pivoteDespuesRompimiento(1,i))return i;
                     return i;
                  }
                }
   
         }  
         //cuando rompe minimo
         if(status == -1){
            
            //determinar si existe pivote     
            piv = pivoteMenorMayor(nI,i,1);
            
            //se dibuja el cambio de tendencia
            alineacionBurbuja(drawLine(nI,i,-1));   
            return i;         
         }
            
      }
   } 
   if(direccion == -1){
      //for para encontrar la siguiente secuencia que mueva el precio
      for(int i = (nI - 1);i>0;i--){
         
         /*
         if( i == 128){
            Comment   ("Hola");
         }
         */
        if(nI - i > NUMREDIBUJO){
            redibujar(nI);
            return NUMREDIBUJO -1;
         }        
         //con esto vemos si rompio algun maximo o minimo
         status = nuevaVelaActualizacion(maximoValue1,minimoValue1,i);
         
         //se pasa a la siguiente iteracion 
         if(status == 0)continue;
         
         //cuando rompe minimo
         if(status == -1){
            
            //determinar si existe pivote     
            piv = pivoteMenorMayor(nI,i,1);
            
            //se busca un pivote entre el minimo y el minimo anterior
            //algoritmo cuando no se encuentra
            if(piv ==-1){
               
               
               nivelesLinea(linea1,1);
               ObjectDelete(0,linea1);                 
               linea1 = drawLine(maximoIndex1,i,-1);
               nivelesLinea(linea1,1);
               if(pivoteDespuesRompimiento(-1,i))return i;
               return i;
            }
            //algoritmo para cuando es la vela anterior y se recorre en el mismo pivote
            if(piv == nI && piv == minimoIndex1 && i == (piv -1)){
               nivelesLinea(linea1,1);
               ObjectDelete(0,linea1);                 
               linea1 = drawLine(maximoIndex1,i,-1);
               nivelesLinea(linea1,1);
               if(pivoteDespuesRompimiento(-1,i))return i;
               return i; 
            }
            else{          
                  //revisamos si tiene la distancia correcta
                  if(distancePivot(piv,i,-1)>=(PIPSIMPULSOMINIMO*10)){   
                     
                     if(pivoteDespuesRompimiento(-1,i))return i;                    
                     alineacionBurbuja(drawLine(nI,piv,1));
                     alineacionBurbuja(drawLine(piv,i,-1));
                     return i;
                  }
                  else{//cuando no tiene la distancia              
                     //secuencia para redibujar la linea1
                     nivelesLinea(linea1,1);
                     ObjectDelete(0,linea1);                 
                     linea1 = drawLine(maximoIndex1,i,-1);
                     nivelesLinea(linea1,1);
                     
                     //pero se busca alomejor en un nivel intermedio si existe esa distancia
                     if(pivoteDespuesRompimiento(-1,i))return i;
                     
                     return i;
                  }
                }
         }  
         //cuando rompe maximo
         if(status == 1){
            
            //determinar si existe pivote     
            piv = pivoteMenorMayor(nI,i,1);
            
            //se dibuja el cambio de tendencia
            alineacionBurbuja(drawLine(nI,i,1));   
            return i;         
         }
            
      }
   } 
   return 0;
}

//+---------------------------------------------------------------------------------+
//|Regresa el tipo de rompimiento de la nueva vela                                  |
//1 rompre el maximo || -1 rompe el minimo || 2 rompe ambos || 0 no rompe ninguno   |
//+---------------------------------------------------------------------------------+

int nuevaVelaActualizacion(double max,double min, int index){
     double maxNuevaVela, minNuevaVela;
     
      maxNuevaVela = iHigh(Symbol(),Period(),index);
      minNuevaVela = iLow (Symbol(),Period(),index);
      
      //rompe el maximo
      if(maxNuevaVela>max){
         if(minNuevaVela < min)return 2;
         
         return 1;
      }
      
      //rompe el minimo
      if(minNuevaVela < min){
         if(maxNuevaVela>max)return 2;
         
         return -1;
      }
      
      return 0;
      
}
//----
//+--------------------------------------------------------------------------------------+
//|  Index a tomar desde donde se cuenta para encontar el siguiente maximo o minimo      |
//+--------------------------------------------------------------------------------------+
int nextIndex(int max,int min){
   
   if(max<=min){
      return max;
   }
   else{
      return min;
   }
   
   //error retorna -1
   return -1;
}

//-----

//+------------------------------------------------------------------+
//|mueve un espacio hacia abajo el conteo de lineas                  |
//+------------------------------------------------------------------+
void alineacionBurbuja(string newLine){

   linea12 = linea11;
   linea11 = linea10;
   linea10 = linea9;
   linea9 = linea8;
   linea8 = linea7;
   linea7 = linea6;
   linea6 = linea5;
   linea5 = linea4;
   linea4 = linea3;
   linea3 = linea2;
   linea2 = linea1;
   linea1 = newLine;  
}

//----
//+------------------------------------------------------------------+
//|Se graban los valores en las variables segun la linea que se deseé|
//+------------------------------------------------------------------+
void nivelesLinea(string line,int num){
   
   int dir = dirLinea(line);
   if(num == 1){
   
      if(dir == 1){
         minimoValue1 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         minimoIndex1 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
         
         maximoValue1 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         maximoIndex1 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
      }
      if(dir == -1){
         minimoValue1 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         minimoIndex1 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
         
         maximoValue1 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         maximoIndex1 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
      }
   }
   if(num == 2){
   
      if(dir == 1){
         minimoValue2 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         minimoIndex2 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
         
         maximoValue2 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         maximoIndex2 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
      }
      if(dir == -1){
         minimoValue2 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         minimoIndex2 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
         
         maximoValue2 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         maximoIndex2 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
      }
   }
   if(num == 3){
   
      if(dir == 1){
         minimoValue3 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         minimoIndex3 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
         
         maximoValue3 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         maximoIndex3 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
      }
      if(dir == -1){
         minimoValue3 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         minimoIndex1 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
         
         maximoValue3 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         maximoIndex3 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
      }
   }
   if(num == 4){
         int tipee=1;
         double ValueFA0,ValueFA1;
         int IndexFA1, IndexFA0;
      
         ValueFA0 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
         IndexFA0 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,0),false);
         
         ValueFA1 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
         IndexFA1 = iBarShift(NULL,Period(),ObjectGetInteger(NULL,line,OBJPROP_TIME,1),false);
         
         if(ValueFA0>ValueFA1)tipee = -1;
         
         drawLine(IndexFA0,IndexFA1,tipee);

   }
}
//+------------------------------------------------------------------+
//|  direccion de la linea                                           |
//+------------------------------------------------------------------+
int dirLinea(string line){
   double ancla0, ancla1;
   
   ancla0 = ObjectGetDouble(0,line,OBJPROP_PRICE,0);
   ancla1 = ObjectGetDouble(0,line,OBJPROP_PRICE,1);
   
   //tendencia alcista
   if(ancla0 <= ancla1){
      
      return 1;
   }
   //tendencia alcista
   if(ancla0 > ancla1){
      return -1;
   }
   
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string drawLine(int time1,int time2,int type)
  {
    string lineName = newName("linea");
    int windowNumber = 0; //0 this means main window
    datetime chartPoint1 = iTime(NULL,Period(),time1);
    double chartValue1 = iLow(Symbol(),Period(),time1);
    
    datetime chartPoint2 = iTime(NULL,Period(),time2);
    double chartValue2 = iHigh(Symbol(),Period(),time2);
    
    color colorLine = clrFuchsia;
    
//----algorithm for the sells
    
    if(type == -1)
    {
      colorLine = clrFuchsia;
      chartValue1 = iHigh(Symbol(),Period(),time1);
      chartValue2 = iLow(Symbol(),Period(),time2);
    }


    if(!ObjectCreate(  0,                  // chart identifier 
                        lineName,           // object name 
                        OBJ_TREND,          //type of object
                        windowNumber,       // Number of subwindow where the line will be draw
                        chartPoint1,        // time where is located the first ancor
                        chartValue1,        // value where is draw the first ancor
                        chartPoint2,        // '' 
                        chartValue2)        // '' 
                        )
        {
          Print("Error: can't create label! code #",GetLastError());  //inform  of the error
          return "NULL";
        }
    ObjectSet( lineName,OBJPROP_RAY,false);
    ObjectSetInteger (0,lineName,OBJPROP_COLOR,colorLine);
    ObjectSetInteger (0,lineName,OBJPROP_WIDTH,2);
    return lineName;
  }

 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string newName(string prefix)
  {
   string namex;
   int existe;

   do
     {
      namex = StringConcatenate(prefix,(string)MathRand());
      existe = ObjectFind(0,namex);
     }
   while(existe != -1);

   return namex;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Retorna el index de la siguiente vela con pivote                 |
//+------------------------------------------------------------------+
int sigPivoteIndex(int indexInicial,int type){
   
   //buscamos la vela que tenga un pivote y asi determinamos la primer tendencia
   
   for(int i = indexInicial;i>0;i--){
   
      if(hasPivot(i, type)){
         return i;
      }   
   } 
   return 0;
   
}

//+------------------------------------------------------------------+
//|   Retorna el tipo de pivote en esta vela                         |
//+------------------------------------------------------------------+
bool hasPivot(int index,int type){
   int pivotType = 0;
   double thisCandelHigh,thisCandelLow;
   double pastCandelHigh,pastCandelLow;
   double nextCandelHigh,nextCandelLow;

   thisCandelHigh = iHigh(Symbol(),Period(),index);
   thisCandelLow  = iLow (Symbol(),Period(),index);
   
   pastCandelHigh = iHigh(Symbol(),Period(),index+1);
   pastCandelLow  = iLow (Symbol(),Period(),index+1);
   
   nextCandelHigh = iHigh(Symbol(),Period(),index-1);
   nextCandelLow  = iLow (Symbol(),Period(),index-1);
   
   //pivote con solo la vela pasada
   if(thisCandelHigh > pastCandelHigh ){
      pivotType = 1;
      if(pivotType == type)return true;
   }
   //pivote superior con vela pasada y siguiente
   if(thisCandelHigh > pastCandelHigh && thisCandelHigh > nextCandelHigh){
      pivotType = 2; 
      if(pivotType == type)return true;
      }
             
   if(thisCandelLow  < pastCandelLow)
      {
      pivotType = -1;
      if(pivotType == type)return true;
      }    
   if(thisCandelLow  < pastCandelLow  && thisCandelLow  < nextCandelLow )
      {
      pivotType = -2;
      if(pivotType == type)return true;
      }
     
   if(pivotType == type){return true;}
   else{return false;}
   
}

//+------------------------------------------------------------------+
//| Retorna la distancia del impulso en puntos                       |
//+------------------------------------------------------------------+

double  distancePivot(int inicioPiv,int finalPiv, int dir) {
   
   double high ,low, distance =0;
   
   //si la direccion es alcista el primer pivote es low el segundo es high
   if(dir == 1){
      high = iHigh(Symbol(),Period(),finalPiv );
      low  = iLow (Symbol(),Period(),inicioPiv);
      
      distance = (high - low )/Point();
   }
   
   //si la direccion es bajista el primer pivote es high segundo low
   if(dir == -1){
      high = iHigh(Symbol(),Period(),inicioPiv);
      low  = iLow (Symbol(),Period(),finalPiv );
      
      distance = (high - low )/Point();
   }
   return distance;
}

//+------------------------------------------------------------------+
//|retorna el index del pivote menor entre esos dos punto           |
//+------------------------------------------------------------------+
int pivoteMenorMayor(int inicio,int fin, int dir){
   int menor = 0;
   double valorTest = 0; double valorfinalmin = 999999999;double valorfinalmax = 0; int fix=-1;
   
   for(int i = inicio;i >=fin;i--){
      
      //para el pivote menor
      if(dir==-1){
         if(hasPivot(i,-2)){
            valorTest = iLow(Symbol(),Period(),i);
            if(valorTest<valorfinalmin){
               valorfinalmin= valorTest;
               fix = i;
            }
         }      
      }
      
      //para el pivote mayor
      if(dir==1){
         if(hasPivot(i,2)){
            valorTest = iHigh(Symbol(),Period(),i);
            if(valorTest>valorfinalmax){
               valorfinalmax= valorTest;
               fix = i;
            }
         }      
      }
      
      
   }
   return fix;
}

//---------------------------------

//+------------------------------------------------------------------+
//|   Regresa el index de donde rompe por primera vez la tendencia   |
//+------------------------------------------------------------------+
bool pivoteDespuesRompimiento(int dir, int fin){
   int  piv2 = 0;
   
   if(dir == 1){
         for(int i= maximoIndex2-1;i>fin;i--)
         {
            int status = nuevaVelaActualizacion(maximoValue2,minimoValue2,i);
            
            if(status == 0)continue;
            //si encuentra el primer punto que rompe se busca entre el primer punto que rompe un pivote
            if(status == 1){
               piv2 = pivoteMenorMayor(i,maximoIndex1,-1);
               if(piv2 == -1)return false;//si no existe el pivote se regresa
               
               //buscamos que ese pivote cumpla con la distancia para saber si es candidato a redibujo
               double dtemp = distancePivot(piv2,maximoIndex1,1);
               if(distancePivot(piv2,maximoIndex1,1)>=(PIPSIMPULSOMINIMO*10)){                                           
                  //secuencia para encontrar el punto minimo entre la linea 1 y 
                  //el pivote encontrado para redibujar la linea 1
                  int linProv = mayorMenorShift(i,piv2,1);
                  double valLinnprob = iHigh(NULL,Period(),linProv);
                  ObjectDelete(0,linea1);                                 
                  linea1 = drawLine(minimoIndex1,linProv,1);  
                                    
                  alineacionBurbuja(drawLine(linProv,piv2,-1));
                  alineacionBurbuja(drawLine(piv2,fin,1));             
                                                     
                  return true;
                  }
            }   
            break;     
         }  
   }
   
   //cuando buscamos en una tendencia bajista
   if(dir ==-1){
      for(int i= minimoIndex2-1;i>fin;i--)
         {
            int status = nuevaVelaActualizacion(maximoValue2,minimoValue2,i);
            
            //si encuentra el primer punto que rompe se busca entre el primer punto que rompe un pivote
            if(status == -1){
               piv2 = pivoteMenorMayor(i,minimoIndex1,1);
               if(piv2 == -1)return false;//si no existe el pivote se regresa
               
               //buscamos que ese pivote cumpla con la distancia para saber si es candidato a redibujo
               double dtemp = distancePivot(piv2,minimoIndex1,-1);
               if(distancePivot(piv2,minimoIndex1,-1)>=(PIPSIMPULSOMINIMO*10)){                                           
                  //secuencia para encontrar el punto minimo entre la linea 1 y 
                  //el pivote encontrado para redibujar la linea 1
                  int linProv = mayorMenorShift(i,piv2,-1);
                  ObjectDelete(0,linea1);                                 
                  linea1 = drawLine(maximoIndex1,linProv,-1);  
                                    
                  alineacionBurbuja(drawLine(linProv,piv2,1));
                  alineacionBurbuja(drawLine(piv2,fin,-1));             
                                                     
                  return true;
                  }
            }        
         } 
   }

   return false;
   
}


//+------------------------------------------------------------------+
//|Secuencia para cambiar la ultima linea a el nombre de linea fib   |
//+------------------------------------------------------------------+
void lineasFib(){


   ObjectDelete(0,"FIB1");
   cambiarNombreLinea(linea2,"FIB1");
   return;

}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cambiarNombreLinea(string objA, string objN){

   int tipee=1;
   double Value0,Value1;
   long Index1, Index0;

   Value0 = ObjectGetDouble(0,objA,OBJPROP_PRICE,0);
   Index0 = ObjectGetInteger(NULL,objA,OBJPROP_TIME,0);
   
   Value1 = ObjectGetDouble(0,objA,OBJPROP_PRICE,1);
   Index1 = ObjectGetInteger(NULL,objA,OBJPROP_TIME,1);
   
   if(Value0>Value1)tipee = -1;
   
   if(!ObjectCreate(  0,                  // chart identifier 
                        objN,             // object name 
                        OBJ_TREND,        //type of object
                        0,              // Number of subwindow where the line will be draw
                        Index0,        // time where is located the first ancor
                        Value0,        // value where is draw the first ancor
                        Index1,        // '' 
                        Value1)        // '' 
                        )
        {
          Print("Error: can't create label! code #",GetLastError());  //inform  of the error
          //return "NULL";
        }
    ObjectSet( objN,OBJPROP_RAY,false);
    ObjectSetInteger (0,objN,OBJPROP_COLOR,clrFuchsia);
    ObjectSetInteger (0,objN,OBJPROP_WIDTH,2);
   
}


//+------------------------------------------------------------------+
//| revuielve el ihightest o ilowest                                                                 |
//+------------------------------------------------------------------+
int mayorMenorShift(int inicio,int fin,int dir ){
   double hg =0,lw = 999999;
   int iHl = -1;
   
   //iHighest
   if(dir ==1){
      for(int i = inicio;i>=fin;i--){
         
         if(iHigh(Symbol(),Period(),i)>hg){
            hg =iHigh(Symbol(),Period(),i);
            iHl = i ;
         }   
      } 
   }
   if(dir ==-1){
      for(int i = inicio;i>=fin;i--){
         
         if(iLow(Symbol(),Period(),i)<lw){
            lw =iLow(Symbol(),Period(),i);
            iHl = i ;
         }   
      } 
   }   
   
 return iHl;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void redibujar(int ultimoPunto){

   int puntoRedibujo =  ultimoPunto - 1;
   
   linea1 = velaInicial(puntoRedibujo);
   linea2 = velaInicial2(puntoRedibujo);
   
   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dibujarFibo(string namex, color col){
   ObjectCreate(NULL,namex,OBJ_FIBO,0,iTime(NULL,timeframe,7),iLow(NULL,timeframe,7),iTime(NULL,timeframe,1),iHigh(NULL,timeframe,1));
  //--- En estas ordenes se checan las propiedades del fibo y se crean los niveles con sus leyendas
   ObjectSetInteger(NULL,namex,OBJPROP_COLOR,clrRed);
   ObjectSetInteger(NULL,namex,OBJPROP_RAY_RIGHT,false);
  //cantidad de niveles
   ObjectSetInteger(NULL,namex,OBJPROP_LEVELS,8);
  //color
   ObjectSetInteger(NULL,namex,OBJPROP_LEVELCOLOR,col);

  //nivel donde se ve el tp del fibo
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,0,0);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,0,"TP");

  //nivel de trampa del fibo
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,1,1);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,1,"NT");

  //nivel minimo donde se revisa la pillada
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,2,1.05);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,2,"");

  //nivel maximo de pillada
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,3,1.55);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,3,"155");

  //nivel maximo de pillada
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,4,0.45);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,4,"TP minimo");

  //TP
    ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,5,2);
    ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,5,"200");
    //TP
    ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,6,2.1);
    ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,6,"210");
    //TP
    ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,7,3);
    ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,7,"300");

  /*
   //nivel de SL
    ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,5,3);
    ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,5,"2x");
   */

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getlevels(string fibNumber){
  //valores de los niveles del fibo
  //los primeros son directos
   nivelTrampa = ObjectGetDouble(NULL,fibNumber,OBJPROP_PRICE,0);
   TP = ObjectGetDouble(NULL,fibNumber,OBJPROP_PRICE,1);

  //shift de los puntos del fibo
   inicioTrampa= iBarShift(NULL,Period(),ObjectGetInteger(NULL,fibNumber,OBJPROP_TIME,0),false);
   finTrampa = iBarShift(NULL,Period(),ObjectGetInteger(NULL,fibNumber,OBJPROP_TIME,1),false);

  //multiplicacion matematica para los demas niveles


   if(nivelTrampa>TP)
     {
      delta = nivelTrampa - TP;
      pilladaMinValor = nivelTrampa + (delta * pilladaMin) ;
      pilladaMaxValor =nivelTrampa + (delta * pilladaMax);
      gestionBE = nivelTrampa +(delta * 1);
      SL = nivelTrampa + (delta * 2);
     }
   else
     {
      delta = TP - nivelTrampa;
      pilladaMinValor = nivelTrampa - (delta * pilladaMin) ;
      pilladaMaxValor =nivelTrampa - (delta * pilladaMax);
      gestionBE = nivelTrampa -(delta * 1);
      SL = nivelTrampa - (delta * 2);
     }

  //Comment("nt = "+nivelTrampa+"\ntp = "+TP+"\npilladamin = "+pilladaMinValor+"\nPilladaMax = "+pilladaMaxValor);

}

//+------------------------------------------------------------------+
//| revision de parametros para establecer si hay una compra         |
//+------------------------------------------------------------------+
void purchaseCheck(){
  //se agrega esta revision para cuando hay error y se crea el loop de revision
  if(TotalOrderCount()>0)
      return;

   double valorMaximoComparar, valorMinimoComparar; //valores de la vela para la pillada
   double velaEntradaOpen, velaEntradaClose, velaEntradaHigh, velaEntradalow; //valores de la vela de entrada para revisar cambio de color y martillo

  //venta  se busca que la pillada sea en la parte superior para buscar una venta
   if(nivelTrampa>TP)
     {
      //ciclo para revisar cada estado despues de la puesta de la trampa
      //y ver si cumple con la pillada o si se descarta por pasar del lugar indicado
      valorMaximoComparar = iHigh(NULL,Period(),iHighest(NULL,Period(),MODE_HIGH,inicioTrampa,1));


      if(valorMaximoComparar>pilladaMinValor && valorMaximoComparar<pilladaMaxValor)
        {
         //toma de valores de la vela de trigger
         velaEntradaOpen  = iOpen (NULL,Period(),1);
         velaEntradaClose = iClose(NULL,Period(),1);
         velaEntradaHigh  = iHigh (NULL,Period(),1);
         velaEntradalow   = iLow  (NULL,Period(),1);

         //en este punto se busca que sea una entrada por cambio de color
         if(velaEntradaClose<velaEntradaOpen) //cambio de color
           {
            if(entradaQuemada(name))
               return;//revisa si ya se dio otra entrada antes
            orderSend(-1);
            //algo para cambio de color
           }

         //para buscar martillos primero se busca que la vela sea del mismo color
         if(velaEntradaClose>velaEntradaOpen && entradaMartillo) //se requiere entrada martillo = true
           {
            double deltaEntrada = velaEntradaHigh - velaEntradalow;
            double puntoMaximoVela = (deltaEntrada/3)+ velaEntradalow;
            if(puntoMaximoVela>=velaEntradaClose)
              {
               if(entradaQuemada(name))
                  return;//revisa si ya se dio otra entrada antes
               orderSend(-1);//algo para funcion de martillo
              }
           }
        }
     }


  //compra en las compras la pillada es la parte inferior
   if(TP>nivelTrampa)
     {
      //ciclo para revisar cada estado despues de la puesta de la trampa
      //y ver si cumple con la pillada o si se descarta por pasar del lugar indicado
      valorMinimoComparar = iLow(NULL,Period(),iLowest(NULL,Period(),MODE_LOW,inicioTrampa,1));

      if(valorMinimoComparar<pilladaMinValor && valorMinimoComparar>pilladaMaxValor)
        {
         //toma de valores de la vela de trigger
         velaEntradaOpen = iOpen(NULL,Period(),1);
         velaEntradaClose = iClose(NULL,Period(),1);
         velaEntradaHigh = iHigh(NULL,Period(),1);
         velaEntradalow = iLow(NULL,Period(),1);

         //en este punto se busca que sea una entrada por cambio de color
         if(velaEntradaClose>velaEntradaOpen) //cambio de color
           {
            if(entradaQuemada(name))
               return;
            orderSend(1);
            //algo para cambio de color
           }

         //para buscar martillos primero se busca que la vela sea del mismo color
         if(velaEntradaClose<velaEntradaOpen && entradaMartillo) //se requiere entrada martillo = true
           {
            double deltaEntrada = velaEntradaHigh - velaEntradalow;
            double puntoMinimoVela = velaEntradaHigh - (deltaEntrada/3) ;
            if(puntoMinimoVela<=velaEntradaClose)
              {
               if(entradaQuemada(name))
                  return;//revisa si ya se dio otra entrada antes
               orderSend(1);//algo para funcion de martillo
              }
           }
        }
     }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void orderSend(int direction){
   double orderPoint,slPoint,tpPoint,lots;                                        //valores para la entrada
   double velaTpClose,velaTpOpen,velaTpHigh,velaTpLow;                            //valores de la vela de tp
   double puntoGestionEmpate, puntoGestionCierre, puntoTakeProfit,puntoStopLoss;  //valores de gestion
   int pipsGestionEmpate, pipsGestionCierre,puntosSL;
   long Magic;
   string TPstring,SLstring;
   double deltaTP;

   TPstring = StringConcatenate("TP",StringSubstr(name,3,0));
   SLstring = StringConcatenate("SL",StringSubstr(name,3,0));


  // vela donde se encuenta el punto maximo de la trampa
   velaTpClose = iClose(NULL,Period(),finTrampa);
   velaTpOpen = iOpen(NULL,Period(),finTrampa);
   velaTpHigh = iHigh(NULL,Period(),finTrampa);
   velaTpLow  = iLow(NULL,Period(),finTrampa);

  //si la trampa mide mas de 60 o menos que 4 se regresa
   if(inicioTrampa > velasMaxTrampa )
     {

      Print("Trampa sobre pasa la cantidad de velas maxima "+ (string)velasMaxTrampa);
      return;
     }

  //algoritmo para las ventas
   if(direction == -1)
     {
      
      double precioActual = Bid;
      
      /*if(Pending20 && (nivelTrampa - (delta*porcentajePending))> precioActual)
        {
         precioActual = nivelTrampa - (delta*porcentajePendingAlocation) ;
         Print("el precio de entrada se mueve al 10% de la tramapa = "+(string)precioActual);
        }
      */

      deltaTP = precioActual - TP;

      //determinar el punto de gestion
      puntoGestionEmpate = iHigh(NULL,Period(),iHighest(NULL,Period(),MODE_HIGH,inicioTrampa,1));
      pipsGestionEmpate = (int)((puntoGestionEmpate - precioActual) / MarketInfo(NULL,MODE_POINT));

      //punto de TP
      //se busca el punto minimo de cuerpo de la vela que dio el maximo de la trampa

      if(ObjectFind(0,TPstring)==0)
        {
         puntoTakeProfit = ObjectGetDouble(NULL,TPstring,OBJPROP_PRICE,0);

         //para cuendo el punto pudiera mandar un punto de error o cuando es mas grande que el FIB
         if(puntoTakeProfit>precioActual || puntoTakeProfit < TP)
           {
            puntoTakeProfit = precioActual -(deltaTP  * tpPorciento);
           }
        }
      else
        {
         puntoTakeProfit = precioActual -(deltaTP  * tpPorciento);
        }

      //revisar la distancia minima de TP
      if(((precioActual - puntoTakeProfit)/Point())  <  TPminimo *10)
        {
         puntoTakeProfit = precioActual - (10*TPminimo*Point());
         Print("Se mueve el TP al ser menor del tp minimo: ");
        }
      
      

      //punto de SL
      //se busca si exite el punto manual
      if(ObjectFind(0,SLstring)==0)//si esto da true buscar el punto donde esta colocado
        {
         puntoStopLoss = ObjectGetDouble(NULL,SLstring,OBJPROP_PRICE,0);
         // Print("salio por objeto");

         //para cuendo el punto pudiera mandar un punto de error
         if(puntoStopLoss< precioActual)
           {
            puntoStopLoss = (precioActual - puntoTakeProfit)*2 + precioActual;
           }
        }
      else //cuando no existe el punto manual se busca el doble matematico
        {
         //delta de la distancia de
         puntoStopLoss = (precioActual - puntoTakeProfit)*2 + precioActual;
         // Print("salio por default");
        }

      //algoritmo para aseguarse que el TP yu SL son los minimos permitidos
      if(((puntoStopLoss - precioActual)/Point())< (TPminimo *10 *2))
         puntoStopLoss = precioActual + (TPminimo*2*Point());




      //algoritmo para crear los pips para crear el rastreo en el magic number
      puntoGestionCierre = ((puntoStopLoss - precioActual)/2)+ precioActual;


      pipsGestionCierre = (int)((puntoGestionCierre - precioActual) / MarketInfo(NULL,MODE_POINT));

      //se regresa la operacion si el punto de cierre es menor a la gestion
      if(pipsGestionCierre<pipsGestionEmpate)
        {
         double porcentajeEntrada;
         porcentajeEntrada = checkTPdistance(entradaPorcentajeMaximo,-1,puntoGestionEmpate);

         Print("Se regresa la operacion en "+(string)puntoTakeProfit+" y el punto de Tp se pone al "+(string)"100%");
         puntoTakeProfit = TP;
         
         Print("Se busca ingresar el nuevo punto de TP en"  +(string)puntoTakeProfit);
         //algoritmo para crear los pips para crear el rastreo en el magic number
         puntoGestionCierre = (precioActual - puntoTakeProfit) + precioActual;
         pipsGestionCierre = (int)((puntoGestionCierre - precioActual) / MarketInfo(NULL,MODE_POINT));
         puntoStopLoss = (precioActual - puntoTakeProfit)*2 + precioActual;

         if(pipsGestionCierre<pipsGestionEmpate)
           {
            Print("Se regresa la operacion ya que el 200% esta obstruido");
            return;
           }
        }
      
      if(TPcuerpo && puntoTakeProfit != TP){
         //algoritmo para cambiar el tp al cuerpo de la vela donde esta el tp
         double puntoTakeProfitnew;
         double tpVelaNewOpen , tpVelaNewClose;
         tpVelaNewOpen  = iOpen (Symbol(),Period(),finTrampa);
         tpVelaNewClose = iClose(Symbol(),Period(),finTrampa);
         if(tpVelaNewOpen > tpVelaNewClose) {puntoTakeProfitnew = tpVelaNewClose;}
         else{puntoTakeProfitnew=tpVelaNewOpen;}
         
         if(puntoTakeProfitnew <puntoTakeProfit) puntoTakeProfit = puntoTakeProfitnew;
      }
      
      
      
      //algortimo para sacar los pips de SL
      puntosSL = (int)((puntoStopLoss - precioActual) /MarketInfo(NULL,MODE_POINT));

      //se normalizan los valores para ser usados en la orden
      orderPoint = NormalizeDouble(precioActual,(int)MarketInfo(NULL,MODE_DIGITS));
      slPoint = NormalizeDouble(puntoStopLoss,(int)MarketInfo(NULL,MODE_DIGITS));
      tpPoint = NormalizeDouble(puntoTakeProfit,(int)MarketInfo(NULL,MODE_DIGITS));

      //se revisa entrada quemada por vela demasiado alta
      /*if(picoQuemado(TP,nivelTrampa,name))
        {
         Print("Operacion quemada 2/3");
         return;
        }
      */




      //se crea el magic
      Magic = crearMagic(01,pipsGestionCierre,pipsGestionEmpate);

      lots = crearLotaje(puntosSL);
      RefreshRates();
      if(Bid > (nivelTrampa - (delta*porcentajePending)))
        {
         //Print("Creado con orden a mercado1");
         RefreshRates();
         orderPoint = Bid;
         if(!OrderSend(NULL,OP_SELL,lots,orderPoint,10,slPoint,tpPoint,NULL,(int)Magic,0,clrNONE))
           {
            Print("OrderSend failed with error #",GetLastError());
            Sleep(1000);
           // purchaseCheck();
           }
         else
           {
            ObjectDelete(0,name);
            //Print("Entrada ="+DoubleToString(orderPoint)+", SL ="+DoubleToString(slPoint)+", TP ="+DoubleToString(tpPoint)+", Magic ="+IntegerToString(Magic));
           }
        }
      else
        {
         if(!Pending20)
           {
            Print("Creado con orden a mercado2");
            RefreshRates();
            if(!OrderSend(NULL,OP_SELL,lots,orderPoint,10,slPoint,tpPoint,NULL,(int)Magic,0,clrNONE))
              {
               Print("OrderSend failed with error #",GetLastError());
               Sleep(1000);
               purchaseCheck();
              }
            else
              {
               ObjectDelete(0,name);
               //Print("Entrada ="+DoubleToString(orderPoint)+", SL ="+DoubleToString(slPoint)+", TP ="+DoubleToString(tpPoint)+", Magic ="+IntegerToString(Magic));
              }
           }
         else
           {
            //Print("Creado con orden pendiente");
            if(!OrderSend(NULL,OP_SELLLIMIT,lots,orderPoint,10,slPoint,tpPoint,NULL,(int)Magic,(cantVelasEspera * PeriodSeconds(PERIOD_CURRENT))+iTime(NULL,Period(),0),clrFuchsia))
              {
               Print("OrderSend failed with error #",GetLastError());
               Sleep(10000);
               RefreshRates();

               if(OrderSend(NULL,OP_SELLLIMIT,lots,orderPoint+(20*Point()),10,slPoint,tpPoint,NULL,(int)Magic,(cantVelasEspera * PeriodSeconds(PERIOD_CURRENT))+iTime(NULL,Period(),0),clrFuchsia))
               {ObjectDelete(0,name);}
                  //Print("Entrada ="+DoubleToString(orderPoint)+", SL ="+DoubleToString(slPoint)+", TP ="+DoubleToString(tpPoint)+", Magic ="+IntegerToString(Magic));
              }
            else
              {
               ObjectDelete(0,name);//Print("Entrada ="+DoubleToString(orderPoint)+", SL ="+DoubleToString(slPoint)+", TP ="+DoubleToString(tpPoint)+", Magic ="+IntegerToString(Magic));
              }

           }


        }


     }

  //algoritmo para las Compras
   if(direction == 1)
     {
      double precioActual = Ask;

     /* if(Pending20 && ( precioActual > (nivelTrampa + (delta*porcentajePending))  ))
        {
         precioActual = nivelTrampa + (delta*porcentajePendingAlocation);
         Print("el precio de entrada se mueve al 10% de la tramapa = "+(string)precioActual);
        }
     */
     
      //determinar el punto de gestion
      puntoGestionEmpate = iLow(NULL,Period(),iLowest(NULL,Period(),MODE_LOW,inicioTrampa,1));
      pipsGestionEmpate = (int)((precioActual - puntoGestionEmpate) / MarketInfo(NULL,MODE_POINT));

      deltaTP = TP - precioActual;
      //punto de TP
      //se busca el punto maximo de cuerpo de la vela que dio el maximo de la trampa


      if(ObjectFind(0,TPstring)==0)
        {
         puntoTakeProfit = ObjectGetDouble(NULL,TPstring,OBJPROP_PRICE,0);
         //para cuendo el punto pudiera mandar un punto de error
         if(puntoTakeProfit<precioActual || puntoTakeProfit > TP)
           {
            /*if(velaTpClose>=velaTpOpen)
              {
               puntoTakeProfit = velaTpClose;
              }
            else
              {
               puntoTakeProfit = velaTpOpen;
              }*/
            puntoTakeProfit = precioActual +(deltaTP  * tpPorciento);
           }
        }
      else
        {
         puntoTakeProfit = precioActual +(deltaTP  * tpPorciento);
        }

      //revisar la distancia minima de TP
      if(((puntoTakeProfit - precioActual)/Point())  <  TPminimo *10)
        {
         puntoTakeProfit = precioActual + (10*TPminimo*Point());
         Print("Se mueve el TP al ser menor del tp minimo: ");
        }


      //punto de SL
      //se busca si exite el punto manual

      if(ObjectFind(0,SLstring)==0)//si esto da true buscar el punto donde esta colocado
        {
         puntoStopLoss = ObjectGetDouble(NULL,SLstring,OBJPROP_PRICE,0);
         //Print("salio por objeto");

         //cuando el sl da error
         if(puntoStopLoss>precioActual)
            puntoStopLoss = precioActual - (puntoTakeProfit - precioActual)*2 ;

        }
      else //cuando no existe el punto manual se busca el doble matematico
        {
         //delta de la distancia de
         puntoStopLoss = precioActual - (puntoTakeProfit - precioActual)*2 ;
         //Print("salio por default");
        }

      //algoritmo para aseguarse que el TP yu SL son los minimos permitidos
      if(((precioActual - puntoStopLoss)/Point())< (TPminimo *10 *2))
         puntoStopLoss = precioActual - (TPminimo*2*Point());

      //algoritmo para crear los pips para crear el rastreo en el magic number
      puntoGestionCierre = precioActual -((precioActual - puntoStopLoss)/2) ;

      pipsGestionCierre = (int)((precioActual - puntoGestionCierre) / MarketInfo(NULL,MODE_POINT));


      //se regresa la operacion si el punto de cierre es menor a la gestion
      if(pipsGestionCierre<pipsGestionEmpate)
        {
         double porcentajeEntrada;
         porcentajeEntrada = checkTPdistance(entradaPorcentajeMaximo,1, puntoGestionEmpate);


         //Print("Se mueve el Tp " +(string)puntoTakeProfit+" a un punto mas grande");
         puntoTakeProfit = TP;
         
         Print("Se busca ingresar el nuevo punto de TP en"  +(string)puntoTakeProfit +"al 100%");
         puntoGestionCierre = precioActual - (puntoTakeProfit - precioActual) ;
         pipsGestionCierre = (int)((precioActual - puntoGestionCierre) /MarketInfo(NULL,MODE_POINT));
         puntoStopLoss = precioActual - (puntoTakeProfit - precioActual)*2 ;

         if(pipsGestionCierre<pipsGestionEmpate)
           {
            Print("Se regresa la operacion por estar obstruido el 200%");
            return;
           }
        }

      if(TPcuerpo && puntoTakeProfit != TP){
         //algoritmo para cambiar el tp al cuerpo de la vela donde esta el tp
         double tpVelaNewOpen , tpVelaNewClose;
         double puntoTakeProfitnew;
         tpVelaNewOpen  = iOpen (Symbol(),Period(),finTrampa);
         tpVelaNewClose = iClose(Symbol(),Period(),finTrampa);
         if(tpVelaNewOpen > tpVelaNewClose) {puntoTakeProfitnew = tpVelaNewOpen;}
         else{puntoTakeProfitnew=tpVelaNewClose;}  
         
         if(puntoTakeProfitnew > puntoTakeProfit) puntoTakeProfit = puntoTakeProfitnew;    
      }
      
      //algortimo para sacar los pips de SL
      puntosSL = (int)((precioActual - puntoStopLoss) /MarketInfo(NULL,MODE_POINT));

      //se normalizan los valores para ser usados en la orden
      orderPoint = NormalizeDouble(precioActual,(int)MarketInfo(NULL,MODE_DIGITS));
      slPoint = NormalizeDouble(puntoStopLoss,(int)MarketInfo(NULL,MODE_DIGITS));
      tpPoint = NormalizeDouble(puntoTakeProfit,(int)MarketInfo(NULL,MODE_DIGITS));

      //se revisa entrada quemada por vela demasiado alta
      /*if(picoQuemado(TP,nivelTrampa,name))
        {
         Print("Operacion quemada 2/3");
         return;
        }*/

      //se crea el magic
      Magic = crearMagic(01,pipsGestionCierre,pipsGestionEmpate);

      //lotaje
      lots = crearLotaje(puntosSL);

      RefreshRates();
      if(Ask < (nivelTrampa + (delta*porcentajePending)))
        {
        RefreshRates();
         orderPoint = Ask;
         if(!OrderSend(NULL,OP_BUY,lots,orderPoint,10,slPoint,tpPoint,NULL,(int)Magic,0,clrNONE))
           {
            Print("OrderSend failed with error #",GetLastError());
            Sleep(1000);
            purchaseCheck();
           }
         else
           {
            ObjectDelete(0,name);
            //Print("Entrada ="+(string)orderPoint+", SL ="+(string)slPoint+", TP ="+(string)tpPoint+", Magic ="+(string)Magic);
           }
        }
      else
        {
         if(!Pending20)
           {
            if(!OrderSend(NULL,OP_BUY,lots,orderPoint,10,slPoint,tpPoint,NULL,(int)Magic,0,clrNONE))
              {
               Print("OrderSend failed with error #",GetLastError());

               Sleep(1000);
               purchaseCheck();
              }
            else
              {
               ObjectDelete(0,name);
               //Print("Entrada ="+(string)orderPoint+", SL ="+(string)slPoint+", TP ="+(string)tpPoint+", Magic ="+(string)Magic);
              }

           }
         else
           {
            Print("Creado con orden pendiente3");
            if(!OrderSend(NULL,OP_BUYLIMIT,lots,orderPoint,10,slPoint,tpPoint,NULL,(int)Magic,(cantVelasEspera * PeriodSeconds(PERIOD_CURRENT))+iTime(NULL,Period(),0),clrFuchsia))
              {
               Print("OrderSend failed with error #",GetLastError());
               Sleep(10000);
               RefreshRates();

               if(OrderSend(NULL,OP_BUYLIMIT,lots,orderPoint-(20*Point()),10,slPoint,tpPoint,NULL,(int)Magic,(cantVelasEspera * PeriodSeconds(PERIOD_CURRENT))+iTime(NULL,Period(),0),clrFuchsia))
               {ObjectDelete(0,name);}
                  //Print("Entrada ="+DoubleToString(orderPoint)+", SL ="+DoubleToString(slPoint)+", TP ="+DoubleToString(tpPoint)+", Magic ="+IntegerToString(Magic));
              }
            else
              {
               ObjectDelete(0,name);//Print("Entrada ="+DoubleToString(orderPoint)+", SL ="+DoubleToString(slPoint)+", TP ="+DoubleToString(tpPoint)+", Magic ="+IntegerToString(Magic));
              }
           }
        }
     }

}

//----algoritmo para crear el magicnumber de seguimiento
int crearMagic(int estrategia,int cierre, int empate){
   /* creamos el magicnumber para la operacion
      314 numero de identificacion del robot
      00 siguintes numero es el tipo de gestion
      0000 siguientes cuatro numero es el numero de gestion de cierre
      0000 siguienters cuatro numeros gestion de empate */
   string est,cie,emp,numeromagico;
   int magic;
   //Print("pips cierre"+(string)cierre+", pips empate"+(string)empate);
  //estrategia normalizada a 2 digitos
   est = IntegerToString(estrategia);
   if(StringLen(est)== 1)
      est = StringConcatenate("0",est);

  //se pasa a string para manipular las variables
   cie = IntegerToString(cierre);
   emp = IntegerToString(empate);

  //normalizar a 4 digitos
   cie = stringAddZero(cie);
   emp = stringAddZero(emp);

   numeromagico = StringConcatenate("17",cie,emp);
   magic = (int)StringToInteger(numeromagico);
   return(magic);
}

//normalizar a 4 digitos string
string stringAddZero(string itera){
   string word;
   if(StringLen(itera)== 1)
      word = StringConcatenate("000",itera);
   if(StringLen(itera)== 2)
      word = StringConcatenate("00",itera);
   if(StringLen(itera)== 3)
      word = StringConcatenate("0",itera);
   if(StringLen(itera)== 4)
      word = itera;
   if(StringLen(itera)>= 5)
      word = StringSubstr(itera,0,4);


   return (word);
}


///algoritomo para contar la cantidad de entradas con el mismo par y con el mismo magic pero solo las dos primeros digitos
int TotalOrderCount(){
   int counte=0;
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
     {
      if(OrderSelect(pos, SELECT_BY_POS)                     // Only my orders w/
         &&  StringSubstr((string)OrderMagicNumber(),0,2)  == (string)17   // primeros dos numeros del magic
         &&  OrderSymbol()       == Symbol())               // and my pair.
        {
         //solamente cuenta si los stoploss estan mas abajo que BE
         if(OrderType() == OP_BUY  && OrderStopLoss() >= OrderOpenPrice())
            continue;
         if(OrderType() == OP_SELL && OrderStopLoss() <= OrderOpenPrice())
            continue;
         counte++;
        }
     }
   return(counte);
}

//revisar si cuando existe porcentaje no hay una entrada que ya activo
//revisa que la entrada ya se quemo por pasar el tercio superior

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool entradaQuemada(string nameObj){
   int nivelt,takeP;
   int puntoMax,puntoMin;
   double valorNivelT,valorTakeP;

  //valores matematicos para saber cual esta arriba
   valorNivelT = ObjectGetDouble(NULL,nameObj,OBJPROP_PRICE,0);
   valorTakeP = ObjectGetDouble(NULL,nameObj,OBJPROP_PRICE,1);

  //shift del nivel donde se trampa
   nivelt = iBarShift(NULL,Period(),ObjectGetInteger(NULL,nameObj,OBJPROP_TIME,0),false);
   takeP = iBarShift(NULL,Period(),ObjectGetInteger(NULL,nameObj,OBJPROP_TIME,1),false);

  //revisa las velas despues del punto maximo para resolver si ya dio la entrada
   if(valorNivelT>valorTakeP)//para las ventas revisa el punto maximo y revisa vela por vela para encontrar entrada
     {
      //revisar que una vela anterior no de entrada
      puntoMax = iHighest(NULL,Period(),MODE_HIGH,nivelt,1);
      for(int i = puntoMax; i > 1 ; i--)
        {
         if(iClose(NULL,Period(),i)<iOpen(NULL,Period(),i))
           {
            return(true);
           }
         if(entradaMartillo)
           {
            double deltaEntrada = iHigh(NULL,Period(),i) - iLow(NULL,Period(),i);
            double puntoMaximoVela = (deltaEntrada/3)+ iLow(NULL,Period(),i);
            if(puntoMaximoVela>=iClose(NULL,Period(),i))
              {
               return(true);
              }
           }
        }

     }
   else //compras
     {
      //se encuentra el shift del punto minimo
      puntoMin = iLowest(NULL,Period(),MODE_LOW,nivelt,1);
      //for para revisar cada vela despues del shift que no este quemada la entrada
      for(int i = puntoMin; i > 1 ; i--)
        {
         if(iClose(NULL,Period(),i)>iOpen(NULL,Period(),i))
           {
            return(true);
           }
         if(entradaMartillo)
           {
            double deltaEntrada = iHigh(NULL,Period(),i) - iLow(NULL,Period(),i);
            double puntoMinimoVela = iHigh(NULL,Period(),i) - (deltaEntrada/3) ;
            if(puntoMinimoVela<=iClose(NULL,Period(),i))
              {
               return(true);
              }
           }

        }
     }


   return false;
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GestionarEntradas(){
   int magicbreak, magicClose, magicBE;      //magic numbers
   string magicletra;                        //magic
   double gestionCierreValor,gestionBEValor; //valores de gestion
   double SlReducido;

   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
     {
      if(OrderSelect(pos, SELECT_BY_POS)                     // Only my orders w/
         &&  StringSubstr((string)OrderMagicNumber(),0,2)  == (string)17   // primeros dos numeros del magic
         &&  OrderSymbol()       == Symbol())               // and my pair.
        {
         magicbreak = OrderMagicNumber();
         magicletra = IntegerToString(magicbreak);
         magicClose = (int)StringToInteger(StringSubstr(magicletra,2,4))+ plusGestionCL;
         magicBE    = (int)StringToInteger(StringSubstr(magicletra,6,4))+ plusGestionBE;

         //Comment("magic ="+magicletra +"\nMagicClose ="+magicClose+"\nMagicBE = "+magicBE);
         /////////////////////////////////VENTAS
         //se encuentran los puntos de gestion
         if(OrderType()==OP_SELL)
           {
              gestionCierreValor = OrderOpenPrice() + (magicClose * MarketInfo(NULL,MODE_POINT));
              gestionBEValor     = OrderOpenPrice() + (magicBE * MarketInfo(NULL,MODE_POINT));

            //cuando cierra por arriba de lagestion de cierre
            if(iClose(NULL,Period(),1)> gestionCierreValor || iOpen(NULL,Period(),0) > gestionCierreValor) //cuando cierra por arriba de la gestion de cierre
              {
               //se manda cerrar la operacion en el punto actual
               if(!OrderClose(OrderTicket(),OrderLots(),Ask,20,clrNONE))
                 {
                  Print("Error al cerrar la operacion"+(string)GetLastError());
                  Sleep(5000);
                  GestionarEntradas();
                 }
               Print("Se cierra operacion por cierre de vela arriba del 50% del stop");
               return;
              }
            //mover a empate por cerrar abajo de punto de gestion
            if(iClose(NULL,Period(),1)> gestionBEValor || iOpen(NULL,Period(),0)> gestionBEValor)//cuando cierra por arriba de la gestion de BE
              {
               if(OrderTakeProfit()>(OrderOpenPrice()-(50*Point())))
                  return;
               //se manda mover el TP a la zona de empate
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice()-(pipsBreakEven*10*MarketInfo(NULL,MODE_POINT)),0,clrNONE))

                 {
                  Print("Error al mover a break even "+(string)GetLastError()+" Ticket: "+(string)OrderTicket());
                  Sleep(5000);
                  //GestionarEntradas();
                 }
               //Print("Se mueve el TP por cerrar por debajo del nivel que mando la trampa");

              }
            //if para mover a un lugar mas cercano el sl
            if(MoverDespuesVela)
              {
               if(iClose(NULL,Period(),1) < OrderOpenPrice() || iOpen(NULL,Period(),0) < OrderOpenPrice() ||  iClose(NULL,Period(),1) > OrderOpenPrice() || iOpen(NULL,Period(),0) > OrderOpenPrice())
                 {
                  SlReducido =  iHigh(NULL,Period(),iHighest(NULL,Period(),MODE_HIGH,5,1))+(MarketInfo(NULL,MODE_SPREAD)*Point());//punto donde se colocara el nuevo sl y se le agrega el spread
                  if(gestionBEValor > SlReducido)
                     SlReducido = gestionBEValor;

                  if(OrderStopLoss() <= SlReducido)
                     return;
                  if(!OrderModify(OrderTicket(),OrderOpenPrice(),SlReducido,OrderTakeProfit(),0,clrNONE))
                    {
                     
                     Print("Error al mover SL "+(string)GetLastError());
                     Print("SL en  "+(string)SlReducido);
                     Sleep(5000);
                     //GestionarEntradas();
                    }
                 }
              }
            if(Reentrada)
              {
               double xs = OrderOpenPrice()- (50*Point());
               if(OrderTakeProfit()>xs && (iClose(NULL,Period(),1)> gestionBEValor || iOpen(NULL,Period(),0)> gestionBEValor))
                 {
                  double velaOpen,velaClose;
                  velaClose = iClose(NULL,Period(),1);
                  velaOpen = iOpen(NULL,Period(),1);
                  int shiftOpen = iBarShift(NULL,Period(),OrderOpenTime());
                  double punto150= iHigh(NULL,Period(),iHighest(NULL,Period(),MODE_LOW,shiftOpen,1));

                  // si la vela es alcista recobrar el TP  y
                  //tambien que el minimo no pase del 150% para buscar reentrada
                  if(velaOpen<velaClose && punto150<gestionCierreValor)
                    {
                     if(OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice()- (magicClose *Point()),0,clrNONE))
                        Print("Se regresa el TP a su punto original");
                    }

                 }
              }
               if(BePositivo)
              {
                //sacamos el delta
                double deltaBE =  (gestionCierreValor - OrderOpenPrice())*(BePositivoPorciento/100);
                deltaBE = OrderOpenPrice() - deltaBE;
                

               if(iLow(NULL,Period(),1) <deltaBE)//punto de gestion
                {
                  Print("Se mueve SL por llegar al punto de BePositivo ="+ (string)deltaBE);
                  if(tipoBePositivo == 0)//cuando se mueve a gestion de BE
                    {
                      
                      if(iClose(NULL,Period(),1)>=gestionBEValor)
                      {
                        if(!OrderClose(OrderTicket(),OrderLots(),Bid,10,clrNONE))Print("Algo sucedio mal con la orden");
                      }                     
                      gestionBEValor = NormalizeDouble(gestionBEValor,(int)MarketInfo(NULL,MODE_DIGITS));
                      if(!OrderModify(OrderTicket(),OrderOpenPrice(),gestionBEValor,OrderTakeProfit(),0,clrNONE))Print("Algo sucedio mal con la orden");
                    }
                  if(tipoBePositivo == 1)//BE
                    {
                      if(iClose(NULL,Period(),1)>=OrderOpenPrice())
                      {
                       if( !OrderClose(OrderTicket(),OrderLots(),Bid,10,clrNONE))Print("Algo sucedio mal con la orden");
                      } 
                      if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(10*Point()),OrderTakeProfit(),0,clrNONE))Print("Algo sucedio mal con la orden");
                    }
                }
                
              }
           }

         /////////////////////////////////COMPRAS
         //se encuentran los puntos de gestion
         if(OrderType()==OP_BUY)
           {
            gestionCierreValor = OrderOpenPrice() - (magicClose * MarketInfo(NULL,MODE_POINT));
            gestionBEValor     = OrderOpenPrice() - (magicBE * MarketInfo(NULL,MODE_POINT));

            if(iClose(NULL,Period(),1) < gestionCierreValor || iOpen(NULL,Period(),0) < gestionCierreValor)//cuando cierra por arriba de la gestion de cierre
              {
               //se manda cerrar la operacion en el punto actual
               if(!OrderClose(OrderTicket(),OrderLots(),Bid,20,clrNONE))
                 {
                  Print("Error al cerrar la operacion"+(string)GetLastError());
                  Sleep(5000);
                  GestionarEntradas();
                 }
               Print("Se cierra operacion por cierre de vela arriba del 50% del stop");
               return;
              }

            if(iClose(NULL,Period(),1)< gestionBEValor || iOpen(NULL,Period(),0)< gestionBEValor)//cuando cierra por arriba de la gestion de BE
              {
               if(OrderTakeProfit()<(OrderOpenPrice()+(50*Point())))
                  return;
               //se manda mover el TP a la zona de empate
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice()+(pipsBreakEven*10*MarketInfo(NULL,MODE_POINT)),0,clrNONE))
                 {
                  Print("Error al mover a break even "+(string)GetLastError()+" Ticket: "+(string)OrderTicket());
                  Sleep(5000);
                  //GestionarEntradas();
                 }
               // Print("Se mueve el TP por cerrar por debajo del nivel que mando la trampa");

              }

            //if para mover a un lugar mas cercano el sl
            if(MoverDespuesVela)
              {
               if(iClose(NULL,Period(),1) > OrderOpenPrice() || iOpen(NULL,Period(),0) > OrderOpenPrice() || iClose(NULL,Period(),1) < OrderOpenPrice() || iOpen(NULL,Period(),0) < OrderOpenPrice())
                 {
                  SlReducido =  iLow(NULL,Period(),iLowest(NULL,Period(),MODE_LOW,5,1))-(MarketInfo(NULL,MODE_SPREAD)*Point());
                  if(gestionBEValor < SlReducido)SlReducido = gestionBEValor;

                  if(OrderStopLoss() >= SlReducido) return;
                  
                  if(!OrderModify(OrderTicket(),OrderOpenPrice(),SlReducido,OrderTakeProfit(),0,clrNONE))
                    {
                     Print("Error al mover SL "+(string)GetLastError());
                     Print("SL en  "+(string)SlReducido);
                     Sleep(5000);
                     //GestionarEntradas();
                    }
                 }
              }
            if(Reentrada)
              {
               double xs = OrderOpenPrice()+ (50*Point());
               if(OrderTakeProfit()<= xs && (iClose(NULL,Period(),1) > gestionBEValor || iOpen(NULL,Period(),0)> gestionBEValor))
                 {
                  double velaOpen,velaClose;
                  velaClose = iClose(NULL,Period(),1);
                  velaOpen = iOpen(NULL,Period(),1);

                  int shiftOpen = iBarShift(NULL,Period(),OrderOpenTime());
                  double punto150= iLow(NULL,Period(),iLowest(NULL,Period(),MODE_LOW,shiftOpen,1));


                  // si la vela es alcista recobrar el TP  y tambien que el minimo no pase del 150% para buscar reentrada
                  if(velaOpen<velaClose && punto150>gestionCierreValor)
                    {
                     if(OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice()+(magicClose*Point()),0,clrNONE))
                        Print("Se regresa el TP a su punto original");
                    }
                 }
              }
            if(BePositivo)
              {
                //sacamos el delta
                double deltaBE =  (OrderOpenPrice() - gestionCierreValor)*(BePositivoPorciento/100);
                deltaBE = OrderOpenPrice() + deltaBE;
                

               if(iHigh(NULL,Period(),1) >deltaBE)//punto de gestion
                {
                  Print("Se mueve SL por llegar al punto de BePositivo ="+ (string)deltaBE);
                  if(tipoBePositivo == 0)//cuando se mueve a gestion de BE
                    {
                      
                      if(iOpen(NULL,Period(),0)<=gestionBEValor)
                      {
                        if(!OrderClose(OrderTicket(),OrderLots(),Bid,10,clrNONE))Print("Algo sucedio mal con la orden");
                      }                     
                      gestionBEValor = NormalizeDouble(gestionBEValor,(int)MarketInfo(NULL,MODE_DIGITS));
                      if(!OrderModify(OrderTicket(),OrderOpenPrice(),gestionBEValor,OrderTakeProfit(),0,clrNONE))Print("Algo sucedio mal con la orden");
                    }
                  if(tipoBePositivo == 1)//BE
                    {
                      if(iClose(NULL,Period(),1)<=OrderOpenPrice())
                      {
                        if(!OrderClose(OrderTicket(),OrderLots(),Bid,10,clrNONE))Print("Algo sucedio mal con la orden");
                      } 
                      if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(10*Point()),OrderTakeProfit(),0,clrNONE))Print("Algo sucedio mal con la orden");
                    }
                }
                
              }
           }
        }
     }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double crearLotaje(int pips){
   double dinero = AccountBalance()  * CantidadRiesgo/100;
   if(RiesgoTipo==1)
      dinero = CantidadRiesgo;
   double tickVal  = MarketInfo(NULL,MODE_TICKVALUE);
   if(tickVal == 0) tickVal = 1;
   double LotSize = dinero/(pips*tickVal);

   if(LotSize<.01)
      LotSize = .01;
   if(RiesgoTipo == 2)
      LotSize = CantidadRiesgo;

   LotSize = MathCeil(LotSize *100);
   LotSize = LotSize /100;
   return LotSize;

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool picoQuemado(double taken,double entrada,string nameObj){
   int nivelt,takeP;
   int puntoMax,puntoMin;
   double deltaQ,puntoMaxValor,puntoMinValor;

  //shift del nivel donde se hace trampa
   nivelt = iBarShift(NULL,Period(),ObjectGetInteger(NULL,nameObj,OBJPROP_TIME,0),false);
   takeP = iBarShift(NULL,Period(),ObjectGetInteger(NULL,nameObj,OBJPROP_TIME,1),false);



  //ademas de ver si dio entrada se va a revisar cada vela para ver que el maximo despues de dar la pillada
  // no supere 2/3 de el tp

   if(entrada>taken) //if para las ventas
     {
      puntoMax = iHighest(NULL,Period(),MODE_HIGH,nivelt,1); // se saca el shif de la vela maxima
      for(int t = puntoMax; t>0; t--)
        {
         if(t == puntoMax)
           {
            double velaIgOpen = iOpen(NULL,Period(),t);
            double velaIgClose = iClose(NULL,Period(),t);
            if(velaIgOpen < velaIgClose)
              {
               //Print ("Se encontro que la misma vela es la que quema la entrada");
               continue;
              }
           }

         deltaQ = entrada - taken;
         puntoMinValor = entrada - (deltaQ*.66);
         if(iLow(NULL,Period(),t)<puntoMinValor)
           {
            // Comment("puntoMaxValor" + puntoMaxValor +"\nPuntoMinValor" +puntoMinValor+"\ndeltaQ"+deltaQ+"\nTP "+taken+"\nEntrada "+entrada);
            //Print ( "El valor que anula es :"+ puntoMinValor);
            return true;
           }
        }
     }
   else //compras
     {
      puntoMin= iLowest(NULL,Period(),MODE_LOW,nivelt,1); // se saca el shif de la vela minima
      for(int t = puntoMin; t>0; t--)
        {
         if(t == puntoMin)
           {
            double velaIgOpen = iOpen(NULL,Period(),t);
            double velaIgClose = iClose(NULL,Period(),t);
            if(velaIgOpen > velaIgClose)
              {
               //Print ("Se encontro que la misma vela es la que quema la entrada");
               continue;
              }
           }
         deltaQ = taken - entrada ;
         puntoMaxValor = entrada + (deltaQ*.66);

         if(iHigh(NULL,Period(),t)>puntoMaxValor)
           {
            //Comment("puntoMaxValor" + puntoMaxValor +"\nPuntoMinValor" +puntoMinValor+"\ndeltaQ"+deltaQ+"\nTP "+taken+"\nEntrada "+entrada);
            //Print ( "El valor que anula es :"+ iHigh(NULL,Period(),t));
            return true;
           }

        }
     }
  //Comment("puntoMaxValor" + puntoMaxValor +"\nPuntoMinValor" +puntoMinValor+"\ndeltaQ"+deltaQ+"/nTP "+taken+"\nEntrada "+entrada);
   return false;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getName(int x){
   string nameF;

   nameF = StringConcatenate("FIB",IntegerToString(x));
   if(ObjectFind(NULL,nameF)==0)
     {
      return nameF;
     }
   else
     {
      return "error";
     }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool crearBotones(const long              chart_ID=0,                // chart's ID
                  const string            nameB="Button",            // button name
                  const int               sub_window=0,              // subwindow index
                  const int               x=0,                       // X coordinate
                  const int               y=20,                      // Y coordinate
                  const int               width=75,                  // button width
                  const int               height=18,                 // button height
                  const ENUM_BASE_CORNER  corner=CORNER_RIGHT_UPPER, // chart corner for anchoring
                  const string            text="Close OP"            // text
                        //const int               bgColor = 12
                 ){
      //--- reset the error value
      ResetLastError();
      //--- create the button
      if(!ObjectCreate(chart_ID,nameB,OBJ_BUTTON,sub_window,0,0))
        {
         Print(__FUNCTION__,
               ": failed to create the button! Error code = ",GetLastError());
         return(false);
        }
      //--- set the chart's corner, relative to which point coordinates are defined
      ObjectSetInteger(chart_ID,nameB,OBJPROP_CORNER,corner);
      //--- set button coordinates
      ObjectSetInteger(chart_ID,nameB,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(chart_ID,nameB,OBJPROP_YDISTANCE,y);
      //--- set button size
      ObjectSetInteger(chart_ID,nameB,OBJPROP_XSIZE,width);
      ObjectSetInteger(chart_ID,nameB,OBJPROP_YSIZE,height);

      //--- set the text
      ObjectSetString(chart_ID,nameB,OBJPROP_TEXT,text);
      //--- set button state
      ObjectSetInteger(chart_ID,nameB,OBJPROP_STATE,false);
      //--- set background color
      //ObjectSetInteger(chart_ID,nameB,OBJPROP_BGCOLOR,bgColor);
      //--- set text font
      /*
         ObjectSetString(chart_ID,nameB,OBJPROP_FONT,"Arial");
      //--- set font size
         ObjectSetInteger(chart_ID,nameB,OBJPROP_FONTSIZE,10);
      //--- set text color
         ObjectSetInteger(chart_ID,nameB,OBJPROP_COLOR,clrBlack);

      //--- set border color
         ObjectSetInteger(chart_ID,nameB,OBJPROP_BORDER_COLOR,clrNONE);
      //--- display in the foreground (false) or background (true)
         ObjectSetInteger(chart_ID,nameB,OBJPROP_BACK,false);

      //--- enable (true) or disable (false) the mode of moving the button by mouse
         ObjectSetInteger(chart_ID,nameB,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(chart_ID,nameB,OBJPROP_SELECTED,false);
      //--- hide (true) or display (false) graphical object name in the object list
         ObjectSetInteger(chart_ID,nameB,OBJPROP_HIDDEN,true);
      //--- set the priority for receiving the event of a mouse click in the chart
         ObjectSetInteger(chart_ID,nameB,OBJPROP_ZORDER,0);
      //--- successful execution */
      return(true);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void botenesdeltester(){
   if(ObjectGetInteger(NULL,"Button1",OBJPROP_STATE))
     {
         ObjectSetInteger(NULL,"Button1",OBJPROP_STATE,false);
         Print("Compra manual por boton");
         OPBOTON = true;
         //se manda la orden
         getlevels("FIBX");
         if(nivelTrampa < TP)
            orderSend(1);
         OPBOTON = false;
         ObjectDelete(0,"FIBX");  
     }
     
   if(ObjectGetInteger(NULL,"Button2",OBJPROP_STATE))
     {
        ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
        Print("Venta manual por boton");
        OPBOTON = true;
        //se manda la orden
        getlevels("FIBX");
        if(nivelTrampa > TP)
            orderSend(-1);
        OPBOTON = false;
        ObjectDelete(0,"FIBX");
     }
   if(ObjectGetInteger(NULL,"Button3",OBJPROP_STATE))
     {
        ObjectDelete(0,"FIBX");
        ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
        dibujarFibo("FIBX",clrRed);
     }
   if(ObjectGetInteger(NULL,"Button4",OBJPROP_STATE))
     {
        ObjectDelete(0,"FIB1");
        ObjectSetInteger(NULL,"Button4",OBJPROP_STATE,false);
        dibujarFibo("FIB1",clrBlack);
     }
}



//retorna true si el tiempo esta activo
bool timecheck(){

   if(TimeYear(TimeLocal())<limityear)return true;
   if(TimeYear(TimeLocal())>limityear)return false;
   
   if(TimeMonth(TimeLocal())<limitmonth)return true;
   if(TimeMonth(TimeLocal())>limitmonth)return false;
   
   if(TimeDay(TimeLocal())<=limitday)return true;
   if(TimeDay(TimeLocal())>limitday)return false;  
   
   return false;  
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double checkTPdistance(double porcMax, int dire,double puntoGestionEmpate){
  //puntoTP , PuntoGestionCierre, deltaTP
   double PTP,PGC,DTP;
   int PIP_GC,PIPGE;
   double PA; //precio actual
  //ventas
   if(dire == -1)
     {

      PA = Bid;
      DTP = PA - TP;
      PIPGE =(int) NormalizeDouble((puntoGestionEmpate - PA)/Point(),0);

      //Print("El punto de PIPGE es: "+PIPGE+"  Punto exacto "+puntoGestionEmpate+" Punto actual es ="+ PA +" point ");
      for(double i =tpPorciento; i<=porcMax; i = i+.05)
        {
         PTP = PA - (DTP*i) ;
         PGC = (PA - PTP) + PA ;
         PIP_GC = (int)NormalizeDouble((PGC - PA)/Point(),0);
         // Print("Con % de "+ i+"% los puntos de Gestiuon de cierre son "+PIP_GC);

         if(PIP_GC > PIPGE)
           {
            //Print("Con el porcentaje "+(string)i+"Paso la verificacion GC="+(string)PIP_GC+" GE="+(string)PIPGE);
            return i;
           }
         continue;
        }
     }
  //para las compras COMPRAS
   if(dire == 1)
     {

      PA = Ask;
      DTP = TP - PA;
      PIPGE =(int) NormalizeDouble((PA - puntoGestionEmpate)/Point(),0);

      for(double i =tpPorciento; i<=porcMax; i = i+.05)
        {
         PTP = PA + (DTP*i) ;
         PGC = PA - (PTP - PA);
         PIP_GC = (int)NormalizeDouble((PA - PGC)/Point(),0);

         if(PIP_GC > PIPGE)
           {
            //Print("Con el porcentaje "+(string)i+"Paso la verificacion GC="+(string)PIP_GC+" GE="+(string)PIPGE);
            return i;
           }
         continue;
        }
     }

   return porcMax;
}


bool logdhay(){
   int AccountAprob[];
   int numeroDeCuentas = 4;
   ArrayResize(AccountAprob,numeroDeCuentas);
   int  cuenta = AccountNumber();
   string cuentaString = IntegerToString(cuenta);
   int    nomeroscuenta = StringLen(cuentaString);
   string cuentaCorta = StringSubstr(cuentaString,nomeroscuenta-4,0);
   int cortanumero = (int)StringToInteger(cuentaCorta);
   AccountAprob[0]=cuenta1;
   AccountAprob[1]=cuenta2;
   AccountAprob[2]=cuenta3;
   AccountAprob[3]=cuenta4;

   for(int i =0; i<numeroDeCuentas; i++)
     {
      if(cortanumero==AccountAprob[i])
         return true;
     }
   
   return false;

  }