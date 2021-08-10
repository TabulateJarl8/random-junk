import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

public class ListDir {

    public static void main(String[] args) throws IOException {
        Files.list(new File("/usr/bin").toPath())
                .forEach(path -> {
                    System.out.println(path);
                });
        Files.list(new File("/bin").toPath())
                .forEach(path -> {
                    System.out.println(path);
                });
        Files.list(new File("/usr/local/bin").toPath())
                .forEach(path -> {
                    System.out.println(path);
                });
        Files.list(new File("/usr/sbin").toPath())
                .forEach(path -> {
                    System.out.println(path);
                });
    }

}