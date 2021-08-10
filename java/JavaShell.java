import java.util.NoSuchElementException;
import java.io.IOException;
import java.io.Reader;
import java.io.StringWriter;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class JavaShell
{
    public static void main(final String[] array) {
        System.out.println("Console Terminal Tool v1.5");
        System.out.println(Fore.MAGENTA + "Working Directory: " + System.getProperty("user.dir") + Fore.RESET);
        final Scanner scanner = new Scanner(System.in);
        try {
            while (true) {
                System.out.print("\n" + Fore.GREEN + "> " + Fore.RESET);
                final String nextLine = scanner.nextLine();
                try {
                    final BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(Runtime.getRuntime().exec(nextLine).getInputStream()));
                    String line;
                    while ((line = bufferedReader.readLine()) != null) {
                        System.out.println(Fore.YELLOW + line + Fore.RESET);
                    }
                    bufferedReader.close();
                }
                catch (IOException e) {
                    StringWriter sw = new StringWriter();
                    e.printStackTrace(new PrintWriter(sw));
                    String exception = sw.toString();
                    Pattern p = Pattern.compile("\"([^\"]*)\"");
                   Matcher m = p.matcher(exception);
                   while (m.find()) {
                   	if(exception.contains("\"exit\"")){
                   		System.exit(0);
                   	}else{
                       	System.out.println(Fore.RED + "Unknown Command: " + Fore.RESET + m.group(1));
                   	}
                   }
                }
            }
        }
        catch (IllegalStateException | NoSuchElementException ex2) {
            System.out.println("System.in was closed; exiting");
        }
    }
}

class Fore{
	public static String BLACK = "\u001b[30m";
	public static String RED = "\u001b[31m";
	public static String GREEN = "\u001b[32m";
	public static String YELLOW = "\u001b[33m";
	public static String BLUE = "\u001b[34m";
	public static String MAGENTA = "\u001b[35m";
	public static String CYAN = "\u001b[36m";
	public static String WHITE = "\u001b[37m";
	public static String RESET = "\u001b[0m";
}

class Back{
	public static String BLACK = "\u001b[40m";
	public static String RED = "\u001b[41m";
	public static String GREEN = "\u001b[42m";
	public static String YELLOW = "\u001b[43m";
	public static String BLUE = "\u001b[44m";
	public static String MAGENTA = "\u001b[45m";
	public static String CYAN = "\u001b[46m";
	public static String WHITE = "\u001b[47m";
	public static String RESET = "\u001b[0m";
}