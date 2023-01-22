import java.io.IOException;
import java.util.ArrayList;

import com.espertech.esper.common.client.configuration.Configuration;
import com.espertech.esper.runtime.client.EPRuntime;
import com.espertech.esper.runtime.client.EPRuntimeProvider;
import com.espertech.esper.common.client.EPCompiled;
import com.espertech.esper.common.client.configuration.Configuration;
import com.espertech.esper.compiler.client.CompilerArguments;
import com.espertech.esper.compiler.client.EPCompileException;
import com.espertech.esper.compiler.client.EPCompilerProvider;
import com.espertech.esper.runtime.client.*;

public class Main 
{
    public static EPDeployment compileAndDeploy(EPRuntime epRuntime, String epl) 
    {
        EPDeploymentService deploymentService = epRuntime.getDeploymentService();
        CompilerArguments args = new CompilerArguments(epRuntime.getConfigurationDeepCopy());
        EPDeployment deployment;
        try 
        {
            EPCompiled epCompiled = EPCompilerProvider.getCompiler().compile(epl, args);
            deployment = deploymentService.deploy(epCompiled);
        } 
        catch (EPCompileException e) 
        {
            throw new RuntimeException(e);
        } 
        catch (EPDeployException e) 
        {
            throw new RuntimeException(e);
        }
        return deployment;
    }


    public static void main(String[] args) throws IOException 
    {

        Configuration configuration = new Configuration();
        configuration.getCommon().addEventType(KursAkcji.class);
        EPRuntime epRuntime = EPRuntimeProvider.getDefaultRuntime(configuration);

        /*EPDeployment deployment = compileAndDeploy(epRuntime,
            "select istream data, spolka, 2 * kursOtwarcia - sum(kursOtwarcia) as roznica " +
            "from KursAkcji(spolka = 'Oracle').win:length(2) " +
            "having kursOtwarcia = max(kursOtwarcia) " +
            "and kursOtwarcia != sum(kursOtwarcia)");*/

//25
        /*EPDeployment deployment = compileAndDeploy(epRuntime,
            "select irstream data, kursOtwarcia, spolka " +
            "from KursAkcji.win:length(3)");*/

//26
        /*EPDeployment deployment = compileAndDeploy(epRuntime,
            "select irstream data, kursOtwarcia, spolka " +
            "from KursAkcji(spolka='Oracle').win:length(3)");*/

//27
        /*EPDeployment deployment = compileAndDeploy(epRuntime,
                "select istream data, kursOtwarcia, spolka " +
                "from KursAkcji(spolka='Oracle').win:length(3)");*/

//28
        /*EPDeployment deployment = compileAndDeploy(epRuntime,
                "select istream data, max(kursOtwarcia), spolka " +
                "from KursAkcji(spolka='Oracle').win:length(5)");*/

//29
                /*EPDeployment deployment = compileAndDeploy(epRuntime,
                "select istream data, kursOtwarcia-max(kursOtwarcia) as roznica, spolka " +
                "from KursAkcji(spolka='Oracle').win:length(5)");*/

//30
                /*EPDeployment deployment = compileAndDeploy(epRuntime,
                "select istream data, ((2*kursOtwarcia)-sum(kursOtwarcia)) as roznica, spolka " +
                "from KursAkcji(spolka='Oracle').win:length(2) " +
                "having ((2*kursOtwarcia)-sum(kursOtwarcia))>0 AND sum(kursOtwarcia)!=kursOtwarcia");*/

        /*PART 2*/

//4
        /*EPDeployment deployment = compileAndDeploy(epRuntime,
                "select irstream data, kursZamkniecia, max(kursZamkniecia)"+
                "from KursAkcji(spolka = 'Oracle').win:ext_timed(data.getTime(), 7 days)");

        deployment = compileAndDeploy(epRuntime,
        "select irstream data, kursZamkniecia, max(kursZamkniecia)\n" +
                "from KursAkcji(spolka = 'Oracle').win:ext_timed_batch(data.getTime(), 7 days)");*/


//5

        ArrayList<String> zadania = new ArrayList<String>();
        
        //5 index 0
        zadania.add("select istream data, kursZamkniecia, spolka, max(kursZamkniecia)-kursZamkniecia as roznica " +
                "from KursAkcji.win:ext_timed_batch(data.getTime(), 1 day)");
        //6 index 1
        zadania.add("select istream data, kursZamkniecia, spolka, max(kursZamkniecia)-kursZamkniecia as roznica " +
                "from KursAkcji(spolka = 'IBM' OR spolka='Microsoft' or spolka='Honda').win:ext_timed_batch(data.getTime(), 1 day)");

        //7 index 2
        zadania.add("select istream data, kursZamkniecia, kursOtwarcia, spolka " +
        "from KursAkcji.win:ext_timed_batch(data.getTime(), 1 day) where kursZamkniecia>kursOtwarcia");
        //7b index 3
        zadania.add("select istream data, kursZamkniecia, kursOtwarcia, spolka " +
        "from KursAkcji.win:ext_timed_batch(data.getTime(), 1 day) where KursAkcji.czyWiekszyKursZamkniecia(kursZamkniecia, kursOtwarcia)");
        //8 index 4
        zadania.add("select istream data, kursZamkniecia, spolka, max(kursZamkniecia)-kursZamkniecia as roznica " +
        "from KursAkcji(spolka = 'PepsiCo' OR spolka='CocaCola').win:ext_timed(data.getTime(), 7 days)");
        //9 index 5
        zadania.add("select istream data, kursZamkniecia, spolka " +
        "from KursAkcji(spolka = 'PepsiCo' OR spolka='CocaCola').win:ext_timed_batch(data.getTime(), 1 day) having max(kursZamkniecia) = kursZamkniecia");
        //10 index 6
        zadania.add("select max(kursZamkniecia) as maksimum " +
                "from KursAkcji.win:ext_timed_batch(data.getTime(), 7 days)");
        //11 index 7
        zadania.add("select istream pc.kursZamkniecia as kursPep, cc.kursZamkniecia as kursCoc, cc.data " +
                "from KursAkcji(spolka = 'PepsiCo').win:length(1) as pc join KursAkcji(spolka='CocaCola').win:length(1) as cc on pc.data=cc.data " +
                "where pc.kursZamkniecia>cc.kursZamkniecia");
        //12 index 8
        zadania.add("select istream teraz.data, teraz.kursZamkniecia, teraz.spolka, teraz.kursZamkniecia-pierwsze.kursZamkniecia as roznica " +
                "from KursAkcji(spolka = 'PepsiCo' OR spolka='CocaCola').win:length(1) as teraz " +
                "join KursAkcji(spolka = 'PepsiCo' OR spolka='CocaCola').std:firstunique(spolka) as pierwsze on teraz.spolka=pierwsze.spolka");
        //13 index 9
        zadania.add("select istream teraz.data, teraz.kursZamkniecia, teraz.spolka, teraz.kursZamkniecia-pierwsze.kursZamkniecia as roznica " +
                "from KursAkcji.win:length(1) as teraz " +
                "join KursAkcji.std:firstunique(spolka) as pierwsze on teraz.spolka=pierwsze.spolka having teraz.kursZamkniecia>pierwsze.kursZamkniecia");
        //14 index 10
        zadania.add("select istream A.data, B.data, A.kursOtwarcia, B.kursOtwarcia, A.spolka " +
                "from KursAkcji.win:ext_timed(data.getTime(), 7 days) as A " +
                "join KursAkcji.win:ext_timed(data.getTime(), 7 days) as B on A.spolka=B.spolka " +
                "where B.kursOtwarcia - A.kursOtwarcia > 3");
        //15 index 11
        zadania.add("select istream data, spolka, obrot  " +
                "from KursAkcji(market='NYSE').win:ext_timed_batch(data.getTime(), 7 days) " +
                "order by obrot desc limit 3");
        //16 index 12
        zadania.add("select istream data, spolka, obrot  " +
                "from KursAkcji(market='NYSE').win:ext_timed_batch(data.getTime(), 7 days) " +
                "order by obrot desc limit 1 offset 2");

        EPDeployment deployment = compileAndDeploy(epRuntime, zadania.get(12));



        ProstyListener prostyListener = new ProstyListener();
        for (EPStatement statement : deployment.getStatements()) 
        {
            statement.addListener(prostyListener);
        }

        InputStream inputStream = new InputStream();
        inputStream.generuj(epRuntime.getEventService());
    }
}
