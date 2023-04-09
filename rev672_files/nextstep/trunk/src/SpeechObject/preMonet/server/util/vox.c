current_values_to_table()
{
float temp;
float table_inc, rc_scale, a, b, c, d;
float a, b, c;

	/*  OSCILLATOR FREQUENCY TO INCREMENT AND SCALING FACTOR  */
	/*  FX parameters Micro & Macro intonation and Minimalization. */
	temp = current_values[11] + current_values[12] + current_values[13];

    /*  READ THE TABLE FROM THE INPUT FILE  */
/*    fread((char *)&table_buffer,sizeof(inputTable),1,fp1);*/


	/*  CONVERT EACH TABLE TO APPROPRIATE DSP VALUES, WRITE TO VM  */
	/*  VOICING OSCILLATOR FREQUENCY  */
	table_inc = (float)(WAVE_TABLE_SIZE * temp)/SAMPLE_RATE;

	*(cur_index_in++) = DSPIntToFix24((int)table_inc);
	*(cur_index_in++) = DSPFloatToFix24(table_inc - (float)((int)table_inc));

	rc_scale = scale_rc / (2.0 * sin(temp * PI_DIV_SR));
	*(cur_index_in++) = DSPIntToFix24((int)rc_scale);
	*(cur_index_in++) = DSPFloatToFix24(rc_scale - (float)((int)rc_scale));

	/*  VOICING OSCILLATOR VOLUME  */
	*(cur_index_in++) = DSPFloatToFix24(amplitude(current_values[0]));
	
	/*  MASTER VOLUME  */
	*(cur_index_in++) = DSPFloatToFix24(amplitude(calc_info.volume));
	
	/*  ASPIRATION VOLUME  */
	*(cur_index_in++) = DSPFloatToFix24(amplitude(current_values[5]));
	
	/*  FRICATION VOLUME  */
	*(cur_index_in++) = DSPFloatToFix24(amplitude(current_values[6]));
	
	/*  BYPASS REGISTER  */
	*(cur_index_in++) = DSPIntToFix24(table_buffer.br);
	
	/*  STEREO BALANCE  */
	*(cur_index_in++) = DSPFloatToFix24((table_buffer.bal * 0.5) + 0.5);
	
	/*  NASAL BYPASS  */
	*(cur_index_in++) = DSPFloatToFix24(current_values[10]);
	
	/*  R1 FREQUENCY AND BANDWIDTH  */
	set_resonator_coefficients(current_values[1],50.0,&a,&b,&c);
	*(cur_index_in++) = DSPFloatToFix24(c);
	*(cur_index_in++) = DSPFloatToFix24(b - 1.0); 
	*(cur_index_in++) = DSPFloatToFix24(a - 1.0);
	
	/*  R2 FREQUENCY AND BANDWIDTH  */
	set_resonator_coefficients(current_values[2],70.0,&a,&b,&c);
	*(cur_index_in++) = DSPFloatToFix24(c);
	*(cur_index_in++) = DSPFloatToFix24(b - 1.0); 
	*(cur_index_in++) = DSPFloatToFix24(a - 1.0);
	
	/*  R3 FREQUENCY AND BANDWIDTH  */
	set_resonator_coefficients(current_values[3],110.0,&a,&b,&c);
	*(cur_index_in++) = DSPFloatToFix24(c);
	*(cur_index_in++) = DSPFloatToFix24(b - 1.0); 
	*(cur_index_in++) = DSPFloatToFix24(a - 1.0);
	
	/*  R4 FREQUENCY AND BANDWIDTH  */
	set_resonator_coefficients(current_values[4],250.0,&a,&b,&c);
	*(cur_index_in++) = DSPFloatToFix24(c);
	*(cur_index_in++) = DSPFloatToFix24(b - 1.0); 
	*(cur_index_in++) = DSPFloatToFix24(a - 1.0);
	
	/*  FRICATION RESONATOR FREQUENCY AND BANDWIDTH  */
	set_resonator_coefficients(current_values[7],current_values[8],&a,&b,&c);
	*(cur_index_in++) = DSPFloatToFix24(c);
	*(cur_index_in++) = DSPFloatToFix24(b - 1.0); 
	*(cur_index_in++) = DSPFloatToFix24(a - 1.0);
	
	/*  NASAL NOTCH FILTER FREQUENCY AND BANDWIDTH  */
	set_notch_filter_coefficients(current_values[9],100.0,&a,&b,&c,&d);
	*(cur_index_in++) = DSPFloatToFix24(a);
	*(cur_index_in++) = DSPFloatToFix24(b);
	*(cur_index_in++) = DSPFloatToFix24(c);
	*(cur_index_in++) = DSPFloatToFix24(d);
	
	/*  SET BALANCE OF TABLE TO ZERO  */
	*(cur_index_in++) = DSPIntToFix24(0);
	*(cur_index_in++) = DSPIntToFix24(0);

}