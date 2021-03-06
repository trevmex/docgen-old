package org.freemarker.docgen;

import java.io.File;
import java.io.IOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.w3c.dom.Document;
import org.xml.sax.DTDHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;

import com.thaiopensource.util.PropertyMapBuilder;
import com.thaiopensource.validate.IncorrectSchemaException;
import com.thaiopensource.validate.Schema;
import com.thaiopensource.validate.SchemaReader;
import com.thaiopensource.validate.ValidateProperty;
import com.thaiopensource.validate.ValidationDriver;
import com.thaiopensource.validate.Validator;
import com.thaiopensource.validate.auto.AutoSchemaReader;
import com.thaiopensource.validate.prop.rng.RngProperty;
import com.thaiopensource.xml.sax.DraconianErrorHandler;
import com.thaiopensource.xml.sax.Jaxp11XMLReaderCreator;

import static org.freemarker.docgen.DocBook5Constants.*;

/**
 *  Used for validating DocBook 5 with RelaxNG. Depends on Jing classes; don't
 *  link to this class statically if you are not sure that Jing is available.
 *  iso_relax is not used, so all you need is <tt>jing.jar</tt>.
 */
final class RelaxNGValidator {

    private static final Set<String> ELEMENTS_WITH_LOCATION;
    static {
        HashSet<String> elemWithLocation = new HashSet<String>();
        
        elemWithLocation.addAll(DOCUMENT_STRUCTURE_ELEMENTS);
        elemWithLocation.add(E_TABLE);
        elemWithLocation.add(E_INFORMALTABLE);
        elemWithLocation.add(E_IMAGEDATA);
        
        ELEMENTS_WITH_LOCATION = Collections.unmodifiableSet(elemWithLocation);
    }

    // Can't be instantiated
    private RelaxNGValidator() {
        // Nop
    }
    
    /**
     * Builds W3C DOM tree from an XML file while it validates it with Relax NG.
     * Supports XInclude.
     */
    public static Document load(File f, DocgenValidationOptions validationOps)
            throws IOException, SAXException {
        CollectingErrorHandler collErrorHandler
                = new CollectingErrorHandler(15);
        
        // We will not use the DocumentBuilderFactory or SAXParserFactory that
        // comes for example with iso_relax, because they don't support
        // XInclude (as of 2009-02-21).
        // We also won't just use a DocumentBuilderFactory and then validate
        // the W3C DOM tree, because then there will not be location information
        // attached to the validation errors.
        
        // Jing-specific stuff:
        
        // - Create the DocBook Relax NG schema:
        PropertyMapBuilder schemaProps = new PropertyMapBuilder();
        ValidateProperty.XML_READER_CREATOR.put(
                schemaProps, new Jaxp11XMLReaderCreator());
        ValidateProperty.ERROR_HANDLER.put(
                schemaProps, new DraconianErrorHandler());
        RngProperty.CHECK_ID_IDREF.add(schemaProps);
        SchemaReader scemaReader = new AutoSchemaReader();
        Schema schema;
        try {
            schema = scemaReader.createSchema(
                    ValidationDriver.uriOrFileInputSource(
                            RelaxNGValidator.class.getResource(
                                "schema/docbook.rng").toString()),
                    schemaProps.toPropertyMap());
        } catch (IncorrectSchemaException e) {
            throw new BugException(
                    "Failed to load DocBook Realx NG schema "
                    + "(see cause exception).",
                    e);
        }
        
        // - Create the validator:
        PropertyMapBuilder valiadtorProps = new PropertyMapBuilder();
        ValidateProperty.XML_READER_CREATOR.put(
                valiadtorProps, new Jaxp11XMLReaderCreator());
        // Used for validation errors:
        ValidateProperty.ERROR_HANDLER.put(
                valiadtorProps, collErrorHandler);
        RngProperty.CHECK_ID_IDREF.add(valiadtorProps);
        Validator validator = schema.createValidator(
                valiadtorProps.toPropertyMap());
        
        // JAXP/SAX stuff:
        
        // - Usual SAX setup:
        SAXParserFactory spf = XMLUtil.newSAXParserFactory(); 
        SAXParser sp;
        try {
            sp = spf.newSAXParser();
        } catch (ParserConfigurationException e) {
            throw new BugException(
                    "Failed to create SAXParser "
                    + "(see cause exception).", e);
        }
        XMLReader xr = sp.getXMLReader();
        xr.setErrorHandler(collErrorHandler); // used for well-formedness errors
        
        // - Inject the Realx NG validator plus the DOM builder: 
        ValidatingDOMBuilder domBuilder;
        try {
            domBuilder = new ValidatingDOMBuilderWithLocations(
                    new DocgenRestrictionsValidator(
                            validator.getContentHandler(),
                            collErrorHandler, collErrorHandler,
                            validationOps),
                    XMLNS_DOCBOOK5,
                    ELEMENTS_WITH_LOCATION);
        } catch (ParserConfigurationException e) {
            throw new BugException(
                    "Failed to create DOM builder "
                    + "(see cause exception).", e);
        }
        xr.setContentHandler(domBuilder);
        
        // - Some helper for the Relax NG validator...
        DTDHandler dh = validator.getDTDHandler();
        if (dh != null) {
            xr.setDTDHandler(dh);
        }
        
        // Parsing:
        
        try {
            xr.parse(ValidationDriver.fileInputSource(f));
        } catch (SAXParseException e) {
            // Throw only if we didn't catch the error in the errorHander. 
            if (collErrorHandler.getErrors().size() == 0) {
                throw e;
            }
        }
        if (collErrorHandler.getErrors().size() != 0) {
            List<String> errors = collErrorHandler.getErrors();
            StringBuilder sb = new StringBuilder(
                    "The XML wasn't valid:\n\n");
            for (String error : errors) {
                sb.append(error);
                sb.append('\n');
            }
            throw new SAXException(sb.toString());
        }
        
        return domBuilder.getDocument();
    }
    
}
