#print('\nThis is my python file')

import sys
import csv
import glob
import os
import pandas as pd
import numpy as np
import seaborn as sb
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
from matplotlib.pyplot import step, show
from fpdf import FPDF
from datetime import datetime
import six


base_color = sb.color_palette()[0]
warning_message = "initial"
dir_path = os.path.dirname(os.path.realpath(__file__))
file_name = dir_path+"/csv_data/"+sys.argv[1]
host = sys.argv[2]

#parse the date taken from shell script as a list
passed_time_list = sys.argv[3:]
passed_time = ""
for i in range (len(passed_time_list)):
    passed_time += passed_time_list[i]
    if i!=6:
        passed_time += ' '


def data_analysis():

   
    if len(sys.argv) <4 :
        sys.stderr.write("Usage:./newAuto.sh filename.csv\n".format(sys.argv[0]))
        exit()


    try:
        df = pd.read_csv(file_name)
    except:
        sys.stderr.write("You Don't Have Any Open Port! No Data to analyze...".format(sys.argv[0]))
        sys.stderr.write("Thank you for using the service...")
        sys.exit(2)


   
    
    sb.set_style("darkgrid")
    df_of_open_ports = df.loc[lambda df: df['STATE'] == "open"]
   
   
    # services visuals
    ax = sb.countplot(x="SERVICE", data=df_of_open_ports,palette="Set2")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=40, ha="right")
    plt.tight_layout()
    ax.yaxis.get_major_locator().set_params(integer=True)
    ax.figure.savefig("/home/kali/Desktop/src/photos/service-result.png")


    # ports visuals
    ax = sb.countplot(x="PORT", data=df_of_open_ports,palette="Set2")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=40, ha="right")
    plt.tight_layout()
    ax.yaxis.get_major_locator().set_params(integer=True)
    ax.figure.savefig("/home/kali/Desktop/src/photos/port-result.png")


    # state visuals
    ax = sb.countplot(x="STATE", data=df,palette="Set2")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=40, ha="right")
    plt.tight_layout()
    ax.yaxis.get_major_locator().set_params(integer=True)
    ax.figure.savefig("/home/kali/Desktop/src/photos/state-result.png")
    

#Report generation
def reports():
    
    warning_message = anomaly_detection()
    now = datetime.now()
    timenow = now.strftime("%d/%m/%Y")

    #images
    
    logo_img = "/home/kali/Desktop/src/photos/logo.png"
    service_img = "/home/kali/Desktop/src/photos/service-result.png"
    port_img = "/home/kali/Desktop/src/photos/port-result.png"
    multi_img = "/home/kali/Desktop/src/photos/multi-result.png"
    state_img = "/home/kali/Desktop/src/photos/state-result.png"
    susb_data_img = "/home/kali/Desktop/src/photos/susb_data.png"

    #messages
    report_message4 = "Thank You for using the service..."
    report_message5 = "Cyber security team."
    report_message6 = "King Saud University - SEC 505 project"

    report_message7 = "Current features include:"
    report_message8 = "1. Collecting network data automatically"
    report_message9 = "2. Analyzing the collected network data"
    report_message10 = "3. Generate reports of the network status"
    new_feture1 = "4. Detect new discovered ports"
    new_feture2 = "5. Display warning message of the new detected ports"
    
    report_message1 ="Results of analyzing IP: " + host +" computer"
    report_message2 = "You have the following services running:"
    report_message3 = "You have some ports open! try to close unnecessarily ports:"
    state_message = "The state of running ports is shown below:"



    pdf = FPDF()
    #page1: Cover page
    pdf.add_page()
    pdf.set_font('Arial','B',22);
    pdf.set_text_color(173,216,230)

    pdf.cell(200, 10, txt = report_message1,ln = 1, align = 'C')
    pdf.image(logo_img, w=pdf.w/2.0, h=pdf.h/4.0,x=50)
    pdf.cell(200, 10, txt = report_message6,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = timenow,ln = 4, align = 'C')
        
    pdf.set_font('Arial','B',16);
    pdf.set_text_color(176,196,222)
    pdf.ln(25)
    pdf.cell(200, 10, txt = report_message7,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = report_message8,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = report_message9,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = report_message10,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = new_feture1,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = new_feture2,ln = 4, align = 'C')



    #page2: graphs
    pdf.add_page()
    pdf.set_text_color(0,76,153)
    
    pdf.cell(200, 10, txt = report_message2,ln = 2, align = 'C')
    pdf.image(service_img, w=pdf.w/2.0, h=pdf.h/4.0,x=50)
    pdf.ln(0.15)
    
    pdf.cell(200, 10, txt = state_message,ln = 3, align = 'C')
    pdf.image(state_img, w=pdf.w/2.0, h=pdf.h/4.0, x=50)
    pdf.ln(0.15)
   
    pdf.cell(200, 10, txt = report_message3,ln = 3, align = 'C')
    pdf.image(port_img, w=pdf.w/2.0, h=pdf.h/4.0, x=50)
    pdf.ln(0.15)

    #page 3: Conclude
    pdf.add_page()
    pdf.set_text_color(255,0,0)
    pdf.cell(200, 10, txt = warning_message,ln = 4, align = 'C')
    try:
        pdf.image(susb_data_img, w=pdf.w/2.0, h=pdf.h/4.0, x=50)
    except:
        pass
    pdf.set_text_color(0,76,153)
    pdf.cell(200, 10, txt = report_message4,ln = 4, align = 'C')
    pdf.cell(200, 10, txt = report_message5,ln = 4, align = 'C')
   
    report_name = "/home/kali/Desktop/src/reports/final_report_"+passed_time+".pdf"  
    pdf.output(report_name)


def anomaly_detection():


    #change name of current to the one provided by shell/py?
    myFolder = 'csv_data'
    files = []
    results = []
    susp_list = []

#new scan
    current_file_name = "csv_data/"+sys.argv[1]
    current_file = pd.read_csv(current_file_name)
        

#results of comparasion
    results_file_name = 'results.csv'

    if not os.path.exists(myFolder):
        os.makedirs(myFolder)

#Multi csv files
    for file in glob.glob('csv_data/*.csv'):
        if file == current_file_name:
            continue;
        files.append(file)

        with open(os.path.join(os.getcwd(),file),mode='r') as myfile:
            try:
                df = pd.read_csv(myfile)
            except:
                continue;
            for port in current_file['PORT']:
                if port not in df.values:
                    if port not in susp_list:
                        susp_list.append({'PORT': port})
            
    susp_df = pd.DataFrame(susp_list, columns = ['PORT'])


    for file in glob.glob('csv_data/*.csv'):
        if file == current_file_name:
            continue;
        files.append(file)

        with open(os.path.join(os.getcwd(),file),mode='r') as myfile:
            try:
                df = pd.read_csv(myfile)
            except:
                continue;
            for port in susp_df['PORT']:
                if port in df.values:
                    susp_df = susp_df[susp_df.PORT != port]

        
    susp_df = susp_df.drop_duplicates()
    if len(susp_df)>0:
        warning_message = "\n WARNINIG: "+str(len(susp_df))+" NEW PORTS DETECTED!!"
#        fig,ax = render_mpl_table2(susp_df, header_columns=0, col_width=0.25)
#        fig.savefig("/home/kali/Desktop/src/photos/susb_data.png")

    else:
        warning_message = 'NO NEW PORTS DETECTED.. '
    
    return warning_message
 

def render_mpl_table2(data, col_width=3.0, row_height=3, font_size=14,
                     header_color='#40466e', row_colors=['#f1f1f2', 'w'], edge_color='w',
                     bbox=[0, 0, 1, 1], header_columns=0,
                     ax=None, **kwargs):
    if ax is None:
        size = (np.array(data.shape[::-1]) + np.array([0, 1])) * np.array([col_width, row_height])
        fig, ax = plt.subplots(figsize=size)
        ax.axis('off')

    mpl_table = ax.table(cellText=data.values, bbox=bbox, colLabels=data.columns, **kwargs)

    mpl_table.auto_set_font_size(False)
    mpl_table.set_fontsize(font_size)

    for k, cell in six.iteritems(mpl_table._cells):
        cell.set_edgecolor(edge_color)
        if k[0] == 0 or k[1] < header_columns:
            cell.set_text_props(weight='bold', color='w')
            cell.set_facecolor(header_color)
        else:
            cell.set_facecolor(row_colors[k[0]%len(row_colors) ])
    return ax.get_figure(), ax


#main

def main():
    data_analysis()
    reports()
#    anomaly_detection()
    exit()

if __name__ == "__main__":
    main()
