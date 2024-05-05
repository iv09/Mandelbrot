#include <iostream>
#include <complex>
#include <complex.h>
#include <tgmath.h>
#include "common.hpp"
#include <cmath>
#include "raylib.h"

using namespace std; //test

const int WindowWidth = 1400;
const int WindowHeight = 1050;
	

double GetColorValueFromFormula(int formula, double x)
{
    /* the input gray x is supposed to be in interval [0,1] */
    if (formula < 0) {		/* negate the value for negative formula */
	x = 1 - x;
	formula = -formula;
    }
    switch (formula) {
    case 0:
	return 0;
    case 1:
	return 0.5;
    case 2:
	return 1;
    case 3:			/* x = x */
	break;
    case 4:
	x = x * x;
	break;
    case 5:
	x = x * x * x;
	break;
    case 6:
	x = x * x * x * x;
	break;
    case 7:
	x = sqrt(x);
	break;
    case 8:
	x = sqrt(sqrt(x));
	break;
    case 9:
	x = sin(90 * x * DEG2RAD);
	break;
    case 10:
	x = cos(90 * x * DEG2RAD);
	break;
    case 11:
	x = fabs(x - 0.5);
	break;
    case 12:
	x = (2 * x - 1) * (2.0 * x - 1);
	break;
    case 13:
	x = sin(180 * x * DEG2RAD);
	break;
    case 14:
	x = fabs(cos(180 * x * DEG2RAD));
	break;
    case 15:
	x = sin(360 * x * DEG2RAD);
	break;
    case 16:
	x = cos(360 * x * DEG2RAD);
	break;
    case 17:
	x = fabs(sin(360 * x * DEG2RAD));
	break;
    case 18:
	x = fabs(cos(360 * x * DEG2RAD));
	break;
    case 19:
	x = fabs(sin(720 * x * DEG2RAD));
	break;
    case 20:
	x = fabs(cos(720 * x * DEG2RAD));
	break;
    case 21:
	x = 3 * x;
	break;
    case 22:
	x = 3 * x - 1;
	break;
    case 23:
	x = 3 * x - 2;
	break;
    case 24:
	x = fabs(3 * x - 1);
	break;
    case 25:
	x = fabs(3 * x - 2);
	break;
    case 26:
	x = (1.5 * x - 0.5);
	break;
    case 27:
	x = (1.5 * x - 1);
	break;
    case 28:
	x = fabs(1.5 * x - 0.5);
	break;
    case 29:
	x = fabs(1.5 * x - 1);
	break;
    case 30:
	if (x <= 0.25)
	    return 0;
	if (x >= 0.57)
	    return 1;
	x = x / 0.32 - 0.78125;
	break;
    case 31:
	if (x <= 0.42)
	    return 0;
	if (x >= 0.92)
	    return 1;
	x = 2 * x - 0.84;
	break;
    case 32:
	if (x <= 0.42)
	    x *= 4;
	else
	    x = (x <= 0.92) ? -2 * x + 1.84 : x / 0.08 - 11.5;
	break;
    case 33:
	x = fabs(2 * x - 0.5);
	break;
    case 34:
	x = 2 * x;
	break;
    case 35:
	x = 2 * x - 0.5;
	break;
    case 36:
	x = 2 * x - 1;
	break;
	
    default:
	/* Cannot happen! */
	//FPRINTF((stderr, "gnuplot:  invalid palette rgbformula"));
	x = 0;
    }
    if (x <= 0)
	return 0;
    if (x >= 1)
	return 1;
    return x;
}

int formulaR1 = 7;
int formulaG1 = 5;
int formulaB1 = 15;
int formulaR2 = 30;
int formulaG2 = 31;
int formulaB2 = 32;
double palCorr1 = 1;
double palShift2 = 0.1;
double palMult2 = 0.9;


double MandelbrotCenterX = -0.7;
double MandelbrotCenterY = 0.0;
double MandelbrotScale = 3.2/WindowWidth; // To get the initial -2.30, 0.9 range


int max_iterations = 0;
int iterations_bias = 0;

Color computeColor(int iteration)

{	
	int max_iter_div2 = max_iterations >> 1;
	
	if (iteration >= (max_iter_div2+iterations_bias)) {
		double temp = palCorr1-(double)(iteration-(max_iter_div2+iterations_bias))/(double)(max_iter_div2-iterations_bias)*palCorr1;
			
		return Color{
			(char)(255.0*GetColorValueFromFormula(formulaR1, temp)), // center
			(char)(255.0*GetColorValueFromFormula(formulaG1, temp)),
			(char)(255.0*GetColorValueFromFormula(formulaB1, temp)),
			255,
			};
	} else {
		double temp = palShift2 + (((double)(iteration)/(double)(max_iter_div2+iterations_bias))*palMult2);
		return Color{
			(char)(255.0*GetColorValueFromFormula(formulaR2, temp)),  // outside
			(char)(255.0*GetColorValueFromFormula(formulaG2, temp)),
			(char)(255.0*GetColorValueFromFormula(formulaB2, temp)),
			255,
			};
	}
};
 
int MandleSet()
{
	double xtemp = 0.0;
	double MandelbrotBaseX = MandelbrotCenterX - MandelbrotScale*WindowWidth/2;
	double MandelbrotBaseY = MandelbrotCenterY - MandelbrotScale*WindowHeight/2;

	// Calling Mandle function for every point on the screen.
    for (int Px = 0; Px < WindowWidth; Px ++) {
        for (int Py = 0; Py < WindowHeight; Py ++) {
			double x0 = MandelbrotBaseX + (double)Px*MandelbrotScale;	// scaling
            double y0 = MandelbrotBaseY + (double)Py*MandelbrotScale;	// scaling
            double x = 0.0;
			double y = 0.0;
			int iteration = 0;
			
			
			while ((x*x + y*y <= 4) && (iteration < max_iterations)) {  // joli aussi *max_iterations
				xtemp = x*x - y*y + x0;
				y = 2*x*y + y0;
				x = xtemp;
				iteration++;
			}
				
			DrawPixel(Px,Py, computeColor(iteration));
			
        }
    }
    return 0;
}
 


int main() {
	bool redrawNeeded = false;
	bool exit = false;

	Image capture;
	
	cout << "Maximum number of iterations: ";
	cin >> max_iterations;
	cout << "Iterations Bias " << -max_iterations/2 << " - " << max_iterations/2 << " :" ;
	cin >> iterations_bias;
	
	EnableEventWaiting();
	InitWindow(WindowWidth, WindowHeight, "Mandelbrot");
    
    
    while (!exit)

    {   
        
        BeginDrawing();

        ClearBackground(BLACK);
            
        MandleSet();
	
	capture = LoadImageFromScreen();    // LoadImageFromScreen() must be executed within a begin/end drawing context   
	
	EndDrawing();
        
        redrawNeeded = false;
        
        while(!redrawNeeded && !exit) {
        
			PollInputEvents();
			
			if (IsKeyPressed(KEY_O)) {
				
				MandelbrotScale = MandelbrotScale*2;
				redrawNeeded = true;
			}
			
			if (IsKeyPressed(KEY_ONE)) {
				formulaR1 = 7; formulaR2 = 30; 
				formulaG1 = 5; formulaG2 = 31;
				formulaB1 = 15; formulaB2 = 32;
				palCorr1 = 1;
				palShift2 = 0.1;
				palMult2 = 0.9;
				redrawNeeded = true;
			}
				
 			if (IsKeyPressed(KEY_TWO)) {
				formulaR1 = 30; formulaR2 = 30; 
				formulaG1 = 31; formulaG2 = 31;
				formulaB1 = 32; formulaB2 = 32;
				palCorr1 = 0.97;
				palShift2 = 0.1;
				palMult2 = 0.9;
				redrawNeeded = true;
			}
			
  			if (IsKeyPressed(KEY_THREE)) {
				formulaR1 = 7; formulaR2 = 7; 
				//cout << "formulaR " << formulaR << endl;
				formulaG1 = 5; formulaG2 = 5;
				formulaB1 = 15; formulaB2 = 15;
				palCorr1 = 1;
				palShift2 = 0.0;
				palMult2 = 1;
				redrawNeeded = true;
			}
				
 			if (IsKeyPressed(KEY_FOUR)) {
				formulaR1 = 30; formulaR2 = 7; 
				formulaG1 = 31; formulaG2 = 5;
				formulaB1 = 32; formulaB2 = 15;
				palCorr1 = 0.97;
				palShift2 = 0.00;
				palMult2 = 1;
				redrawNeeded = true;
			}
				
				
      
			
			if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
				
				MandelbrotCenterX = MandelbrotCenterX + (GetMouseX() - WindowWidth/2)* MandelbrotScale;
				MandelbrotCenterY = MandelbrotCenterY + (GetMouseY() - WindowHeight/2)* MandelbrotScale;
				MandelbrotScale = MandelbrotScale/2;
				
				redrawNeeded = true;
			}
			
			if (IsKeyPressed(KEY_C)) {
			    
			    ExportImage(capture, "capture.png");   
			}
			if (WindowShouldClose()) exit=true;
		}
		

       
	}


    CloseWindow();

    return 0;

}
